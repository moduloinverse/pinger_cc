load 'pingable.rb';

class Pinger
  include Pingable

#put your username:password into login_creds or supply them via commandlineargs
  def initialize(login_creds=nil)
    @user_creds = (ARGV != nil)? ARGV[0] : login_creds;
    encode_user_creds;
  end

end


#put in parentese your login "username:password",
#or pass the same string as commandlineargs
pinger = Pinger.new();
pinger.main_fiber().resume()
