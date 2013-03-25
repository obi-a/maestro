dir = Pathname(__FILE__).dirname.expand_path
require dir + 'lib/ragios'

#Replace with Gmail username and password
gmail_account = {username: 'Gmail Username',
                 password: 'Gmail Password'} 

Ragios::GmailNotifier.config(gmail_account)

#replace with twitter credentials
twitter_cred = {consumer_key: 'Consumer Key', 
               consumer_secret: 'Consumer secret',
                 access_token: 'Access Token',
                 access_secret: 'Access Secret'}

Ragios::TwitterNotifier.config(twitter_cred)  

#Replace with amazon credientials for Amazon Simple Email Service Notifier
amazon_account = { access_key: 'abc',
                   secret_key: '123', 
                   send_from: 'alerts <alerts@example.com>' }

Ragios::SESNotifier.config(amazon_account)


database_admin = {username: 'ragios_server',
                 password: 'ragios'} 

Ragios::DatabaseAdmin.config(database_admin)



