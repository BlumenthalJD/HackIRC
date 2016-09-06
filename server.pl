#!/usr/local/bin/perl
#HackIRC Server
use IO::Socket::INET;
use threads;

$|=1;

my ($socket, $client_socket);
my($peeraddress, $peerport);

$socket=new IO::Socket::INET
(
    LocalHost=>'server address',#put server address on this line
    LocalPort=>'7777',
    Proto=>'tcp',
    Listen=>5,
    Reuse=>1
) or die "Error in Socket Creation: $!\n";

$lastTime=time();
$message="";
#$userNum=0;
#%users=();

print "Server waiting for client connection on port 7777...\n";

while (1)
{
    #starts socket
    $client_socket=$socket->accept();

    $peer_address=$client_socket->peerhost();
    $peer_port=$client_socket->peerport();

    #get server message
    $serverMessage=<$client_socket>;
    chomp($serverMessage);
    #print ("$serverMessage\n");

    #goes to newUser thread
    if ($serverMessage eq "newUser")
    {
        # Start a thread to handle the new connection
        my $thread1 = threads->new( \&newUser,$client_socket,$peer_address, $userNum, %users)->detach();
    }

    #goes to lastTime thread
    if ($serverMessage eq "lastTime")
    {
        # Start a thread to handle the lastTime
        my $thread2 = threads->new( \&lastTime,$client_socket,$peer_address, $lastTime)->detach();
    }

    #goes to chat thread
    if ($serverMessage eq "chat")
    {
        #updates time of update
        $lastTime=time();
        # Start a thread to handle the chat input
        my $thread3 = threads->new( \&chatReceive, $client_socket,$peer_address)->detach();
    }

    if ($serverMessage eq "update")
    {
        # Start a thread to handle the chat input
        my $thread4 = threads->new( \&chatSend, $client_socket,$peer_address)->detach();
    }
}

$socket.close();

# Socket request handler
sub newUser
{
    my ($client,$peer, $userNum, %users) = @_;

    #checks for client connection
    if($client->connected)
    {

        #accepts connection and gets info
        print "Accepted connection from $peer_address, $peer_port\n";

        #gets username
        $user=<$client_socket>;
        chomp($user);
        printf "New User: $user\n";

        #sends servername
        $serverName="User's Server";
        print $client_socket "$serverName";

        #sends chat
        open(chat, "chatLog");
        @chatValue=<chat>;
        close(chat);
        print $client_socket "@chatValue";
    }

    # close before thread dies
    close($client);
}

# Socket request handler
sub lastTime
{
    my ($client,$peer, $lastTime) = @_;

    #checks for client connection
    if($client->connected)
    {
        #prints last time
        print $client_socket "$lastTime";
    }

    # close before thread dies
    close($client);
}

# Socket request handler
sub chatReceive
{
    my ($client,$peer) = @_;

    #checks for client connection
    if($client->connected)
    {
         #gets text from user
        $message=<$client_socket>;

        #gets chat
        open(chat, ">>chatLog");
        print chat "$message";
        close(chat);
    }

    # close before thread dies
    close($client);
}

# Socket request handler
sub chatSend
{
    my ($client,$peer) = @_;

    #checks for client connection
    if($client->connected)
    {
        #clears file
        $fileName="chatLog";
        $size=-s $fileName;
        print "$size\n";

        if ($size>500)
        {
            open(file,">chatLog");
            print file " \n";
            close(file);
        }

        #sends chat
        open(chat, "chatLog");
        @chatValue=<chat>;
        close(chat);

        print $client_socket "@chatValue";
    }

    # close before thread dies
    close($client);
}