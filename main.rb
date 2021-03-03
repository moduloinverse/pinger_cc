load 'pingable.rb';

class Pinger
  include Pingable

  def initialize(login_creds=nil)
    @user_creds = (ARGV != nil)? ARGV[0] : login_creds;
    encode_user_creds;
  end

  def main_fiber()
    fiber = Fiber.new {
      10.times {print "\u{1f6f8 20 20 20}"}#🛸
      test_response = test_fiber.resume();
      check_test_response(test_response);
      #try switch server
      10.times {print "\u{1f511 20 20 20}"}#🔑
      login_response = login_fiber.resume()
      exit 1 unless check_login_success(login_response);


      loop do
        jsn = json_parser(ping_fiber.resume().body);
        pp jsn;
        list_fiber.resume();
        print "\u{1f9f0 20 20 20 1f9f0 20 20 20 1f9f0 20 20 20 1f9f0 0a}"#🧰
        print "#{@check_time} a: #{@answer} q: #{@question} \n";
        pp @list_json;
        if jsn['nextPresenceCheck'] && (!@question)
          @question = jsn['nextPresenceCheck']['question'];
          @check_time = Time.now;
          set_answer_delay();#thread with random sleep 200s
        end

        #pp JSON.parse(list_fiber.resume().body)
        sleep(rand(4..19));
        if (@question && @answer && check_presence_updated)
          @check_time, @question, @answer = nil;
        end
      end
    }
  return fiber;
  end
end


#put in parentese your login "username:password",
#or pass the same string as commandlineargs
pinger = Pinger.new();
pinger.main_fiber().resume()
