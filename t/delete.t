use utf8;
use Test::More tests => 3;
use Test::Mock::LWP::Dispatch;
use CoverArtArchive::Indexer::Context;
use CoverArtArchive::Indexer::EventHandler::Delete;
use Net::Amazon::S3;
use Net::RabbitFoot;
use LWP::UserAgent;
use Log::Contextual::SimpleLogger;
use Log::Contextual qw( :log ),
   -logger => Log::Contextual::SimpleLogger->new({ levels_upto => 'emergency' });

my $delete_event = {
    'ev_data' => "1031598329\naff4a693-5970-4e2e-bd46-e2ee49c22de7\npng",
    'ev_type' => 'delete',
    'ev_retry' => undef,
    'ev_extra3' => undef,
    'ev_extra2' => undef,
    'ev_txid' => '810711',
    'ev_extra1' => undef,
    'ev_time' => '2013-07-15 19:31:02.643127+02',
    'ev_id' => '15',
    'ev_extra4' => undef
};

my $rf = Net::RabbitFoot->new()->load_xml_spec()->connect(
    host => 'localhost',
    port => 5672,
    user => 'guest',
    pass => 'guest',
    vhost => '/',
    timeout => 1,
);

my $s3 = Net::Amazon::S3->new(
        aws_access_key_id     => "test",
        aws_secret_access_key => "test",
        retry                 => 0
    );

my $ua = LWP::UserAgent->new;

$ua->map (qr/^.*$/, sub {
    my $request = shift;
    is ($request->method, 'DELETE', 'Delete request made to S3');
    like ($request->uri, qr/mbid-aff4a693-5970-4e2e-bd46-e2ee49c22de7-1031598329.png$/, "Delete request for correct file");

    return HTTP::Response->new( 200 );
});

my $c = CoverArtArchive::Indexer::Context->new (
    dbh => undef,
    lwp => $ua,
    s3 => $s3,
    rabbitmq => $rf);

my $event = CoverArtArchive::Indexer::EventHandler::Delete->new (c => $c);
isa_ok ($event, 'CoverArtArchive::Indexer::EventHandler::Delete');
$event->handle_event ($delete_event);

1;
