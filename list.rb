load 'pingable.rb';

class Observer
  include Pingable

#put your username:password into login_creds or supply them via commandlineargs
  def initialize(login_creds=nil)
    @user_creds = (ARGV != nil)? ARGV[0] : login_creds;
    encode_user_creds;
  end
end


#put in parentese your login "username:password",
#or pass the same string as commandlineargs
observer = Observer.new();
observer.switch_base_url();

loop do
  20.times {print"\u{2588 2588 2588 20}"}#█
  print "\u{0a}";
  pp observer.base_url;
  observer.list_fiber.resume();
  pp observer.list_json;
  20.times {print"\u{2588 2588 2588 20}"}#█
  print "\u{0a}";
  sleep(rand(15..33));
end
