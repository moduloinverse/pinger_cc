require 'base64';
require 'net/http';
require 'uri';
require 'json';
require 'time';

module Pingable
  ENCODED1='aHR0cHM6Ly9sYXVuY2hlcjIwMS5jb21jYXZlLmRlOjgxODI=';#201
  ENCODED2='aHR0cHM6Ly9sYXVuY2hlcjMwMS5jb21jYXZlLmRlOjgxODI=';#301
  # encoded in means of minor string obfuscation

#94.186.161.104 globalways gmbh, stuttgart, ffm, gochsheim97plz
  EXTERN_URL_1 = Base64.decode64(ENCODED1);
#217.239.142.217 deutsche Telekom, dortmund, ffm, osnabrᴞck
# guess what ip portal(dot)cc student(dot)com has
  EXTERN_URL_2 = Base64.decode64(ENCODED2);#lo_mismo
#this is the hash value of jar file, that /updater/getClient spits out,no auth
  CHECKSUM ='5fdee34b788349d81f0e301cad52374ea5dae98f113708b8e4d9656dcd475b69';

  #Base64.encode64(username:password), assert size = 24
  #4/3 n, our n is 18 = 7:10 7+1+10 =18
  #@basic_auth = Base64.encode64(@user_creds);

  attr_accessor :base_url;
  attr_accessor :user_creds, :auth_id, :ping_token;
  attr_accessor :answer, :question, :presence_check_time;
  attr_accessor :list_json, :ping_json;
  attr_accessor :today08, :overview, :last_server_time;

#main fiber, calls other fiber, controlls
  def main_fiber()
    fiber = Fiber.new {
      loop do

        do_login() unless @ping_token

        ping_fiber.resume();
        list_fiber.resume();

        process_and_create_overview();#call before check_presence_updated
        pp @overview;

        if @ping_json['nextPresenceCheck'] && (!@question)
          @question = @ping_json['nextPresenceCheck']['question'];
          @presence_check_time = Time.now;
          set_answer_delay();#thread with random sleep 200s
        end

        sleep(rand(4..19));
        if (@question && @answer && check_presence_updated())
          @presence_check_time, @question, @answer = nil;
        end
      end
    }
  return fiber;
  end

#calls test,calls login
  def do_login()
    switch_base_url;
    10.times {print "\u{1f6f8 20 20 20}"}#🛸
    test_response = test_fiber.resume();
    check_test_response(test_response);

    10.times {print "\u{1f511 20 20 20}"}#🔑
    login_response = login_fiber.resume()
    check_login_success(login_response);

  end



#fiber that runs URL verb: post /login
#login_body taken from cc-launcher.jar called clientInfoModel there
  def login_fiber()
    fiber = Fiber.new do
      loop do
        login_body = {userHome:"C:\\User\\#{@user_creds.split(":")[0]}",
        userDomain:"DESKTOP-#{@user_creds.split(":")[0]}",
        userCountry:'DE',userLanguage:'de',osArch:'amd64',osName:'Windows 10',
        osVersion:'10.0',fileEncoding:'Cp1252',fileSeparator:'\\',
        sunArchDataModel:'64',sunDesktop:'windows',sunCpuIsalist:'amd64',
        javaLauncherPath:'launcher8182',javaRuntimeVersion:'11.0.10+9-LTS'}

        url = (@base_url + '/ping/login');
        response =send_to_server(url,Net::HTTP::Post,true,true,login_body);
        jsn = json_parser(response.body) if response
        @ping_token = jsn["requestId"];#either set or nil
        t1=Time.now();
        @today08 = Time.new(t1.year,t1.month,t1.day,8);
        #here is a good place, requestId from server, is not valid on day switch
        #from server-side pretty bad though, could be bug, could be intentionally
        Fiber.yield(response);
      end
    end
      return fiber;
  end


#fiber that runs URL verb: post /ping
#ping_request_model taken from cc-launcher.jar
  def ping_fiber()
    fiber = Fiber.new do
      loop do
        ping_request_model = {requestId:"#{@ping_token}",
             lastResponseTime:"#{rand(400..1600)}",#System.currentTimeMillis()
             answer:"#{@answer}",userProcessModel:''}

        url = (@base_url + '/ping/ping');
        response =
              send_to_server(url,Net::HTTP::Post,true,true,ping_request_model);
        @ping_json = json_parser(response.body) if response
        Fiber.yield(response);
      end
    end
    return fiber;
  end

#fiber that runs URL verb: get /list
  def list_fiber()
    fiber = Fiber.new do
      loop do
        url = (@base_url + '/ping/list');
        response = send_to_server(url,Net::HTTP::Get,true,false,false);
        @list_json = json_parser(response.body) if response
        #avoiding shallow copy issues
        @overview = json_parser(response.body) if response

        @last_server_time = Time.parse(@list_json['pingList'][-1]['enddate']) if @list_json
        #move to overview
        Fiber.yield(response)
      end
    end
    return fiber;
  end

#fiber that runs URL verb: post /test
  def test_fiber()
    fiber = Fiber.new do
      loop do
        url = (@base_url + '/ping/test');
        response = send_to_server(url,Net::HTTP::Post,true,true,false);
                                                    #auth checksum body
        Fiber.yield(response);
      end
    end
    return fiber;
  end

#encodes base64 username+password for Basic Auth
  def encode_user_creds()
    fail_msg = "user credits fail, expected 4xl3xd:ldld6xl";
    raise fail_msg unless (@user_creds.size() == 18);
    @auth_id = Base64.urlsafe_encode64(@user_creds);
  end

#builds the request to server, based on provided arguments,
#from fibers
#sends out that request to server
#returns either request obj or nil
  def send_to_server(url_to_use, net_http_class,
                           auth_flag=nil, checksum_flag=nil, body=nil)
    response = nil;
    url = URI(url_to_use);#should be with ending
    connection = Net::HTTP.new(url.host, url.port);
    connection.use_ssl = true;
    request = net_http_class.new(url);#Net::HTTP::Post or Net::HTTP::Get as argument

    request['authorization'] = 'Basic ' + @auth_id if auth_flag;
    request['checksum'] = CHECKSUM if checksum_flag;
    request['Content-Type'] = 'application/json';
    request['User-Agent'] = 'Swagger-Codegen/1.2.0-SNAPSHOT/java';
    request.body = body.to_json if body

    begin
      response = connection.request(request);#to rescue
    rescue StandardError => e#*ALL_NET_HTTP_ERRORS => e
      print "\u{0a 1f691 20 20 20 1f692 20 20 20 1f691 20 20 20 0a}"#🚒
      print "#{e.class} occured at: #{Time.now}";
      print "\u{0a 1f692 20 20 20 1f691 20 20 20 1f692 20 20 20 0a}"#🚑
    ensure
      return response;
    end
  end

#simulates user input
#
#sleeps a while (random till 200s, approx. 3 min) then sets answer,
#ready for pinger to send the answer to server
  def set_answer_delay
    Thread.new {
      20.times {print"\u{2588 2588 2588 20}"}#█
      print "#{Thread.current} gonna \u{1f6cc 0a}"#🛌
      sleep(rand(34..200));
      @answer = @question;
      20.times {print"\u{2588 2588 2588 20}"}
      print "#{Thread.current} #{@answer} set, done¡ \u{0a}";
    }
  end


#reports if presence_check_time is listed in ANY "presenceCheckList"
  def check_presence_updated
    updated = false;
    @list_json['presenceCheckList'].each{|📦| updated = true if #1f4e6
      (📦['startTime']..📦['endtime']).include?(@presence_check_time.to_i) }
    return updated;
  end

#rescues json parser, prints string_to_parse on failures
#returns either parsed obj or nil
  def json_parser(str)
    parsed = nil;
    begin
      parsed = JSON.parse(str);
    rescue
      print "\u{1f6a8 20 1f6a8 20 1f6a8 20}could not parse: #{str}\u{0a}"#🚨
    ensure
      return parsed;
    end
  end

#checks that requestId for session is set
  def check_login_success(login_response)#ping_token set or no
    login_response_body_parsed = json_parser(login_response.body);
    if (login_response.code=='200' && login_response_body_parsed && @ping_token)
      print "\u{0a 1f510 20}server replied HTTP-OK to login request\u{0a}";#🔐
      print "\u{1f6c2 20} #{@ping_token} is your 'requestId' for this session\u{0a}";#🛂
      return true;
    else
      print "login body json \u{1f52c 0a}"#🔬
      pp login_response_body_parsed;
      return false;
    end
  end

#checks and prints information whether success or response hash on failures
  def check_test_response(test_response)
    if (test_response && test_response.code=='200')
      print "\u{0a 1f4f6 20}#{@base_url} replied HTTP-OK to test request\u{0a}";#📶
      return true;
    else
      print "test to_hash \u{1f52c 0a}"#🔬
      pp test_response.to_hash();
      return false;
    end
  end

#overview for user,
#and checks for time diff, when over 11 min, will clear out ping_token,
#which will call login
  def process_and_create_overview#today08, list_json, pingList startdate enddate
    diff = (Time.now.to_i - @last_server_time.to_i);#nil.to_i > 0
    #lots of trust to server,that it would always spit out latest value as last,
    #@last_server_time = Time.parse(@list_json['pingList'][-1]['enddate']) if @list_json
    #changes on successfull json parsing @list_json
    #better implement here that last server time
    if @overview
      @overview['active']=(@overview['pingList'].uniq) if @overview['pingList'];
      @overview['pings'] =
        (@overview['presenceCheckList'].uniq) if @overview['presenceCheckList'];
      @overview.delete('pingList');
      @overview.delete('presenceCheckList');
      @overview['active'].each{|x|x.each{|(k,v)|x[k]=Time.parse(v).strftime("%H:%M:%S")}}
      @overview['pings'].each{|x|x.each{|(k,v)|x[k]=Time.parse(v).strftime("%H:%M:%S")}}
      @overview['🏷'] = @ping_token;#1f3f7
      @overview['⌛']={⏲: diff,#231b 23f1
        ⌚: @last_server_time.strftime("%H:%M:%S")};#231a
      if (@ping_json['notifications'] && @ping_json['notifications'].size > 1)
        @overview['📯'] = @ping_json['notifications'] #1f4ef
      end

      #parse as epoch time, will be needed in check_presence_updated
      #if overview parsed list_json also will be there
      @list_json['presenceCheckList'].each{|x|x.each{|(k,v)|x[k]=Time.parse(v).to_i}}

    end

    if (diff > (11*60)) #time diff more than 11 min,
      @ping_token = nil; #will cause login call
    end

#TO IMPLEMENT
    #if any ping_json[notifications] set, print every x min
    # 60sec * 10 600s >>> mod 600 == 0, epoch time with 1_600_000_600
    #@overview['08am']={total_min:nil,remaining_min:nil}#@today08 used here
    #eliminate where endtime > startime
    # ts = Time.parse(p[0][p[0].keys[0]])
    # te = Time.parse(p[0][p[0].keys[1]])


    #diff = (startdate<t0day08) ? (enddate-today08) : (enddate-startdate)
  end

#201 or 301 server to use
  def switch_base_url
    @base_url = Pingable::const_get("EXTERN_URL_#{rand(1..2)}");
  end

  private :send_to_server, :switch_base_url

end
