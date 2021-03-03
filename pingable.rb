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

  ALL_NET_HTTP_ERRORS = [
  Timeout::Error, Errno::EINVAL, Errno::ECONNRESET, Errno::ENETUNREACH ];
  #Base64.encode64(username:password), assert size = 24
  #4/3 n, our n is 18 = 7:10 7+1+10 =18
  #@basic_auth = Base64.encode64(@user_creds);

  # in means of REST api terminology, should be called userPingToken,
  # cuz its temporary.
  # requestId 🌩329 X-Request-ID

  attr_accessor :user_creds, :auth_id, :ping_token;
  attr_accessor :answer, :question, :check_time;
  attr_accessor :list_json;

  def login_fiber()
    fiber = Fiber.new do
      loop do
        login_body = {userHome:"C:\\User\\#{@user_creds.split(":")[0]}",
        userDomain:"DESKTOP-#{@user_creds.split(":")[0]}",
        userCountry:'DE',userLanguage:'de',osArch:'amd64',osName:'Windows 10',
        osVersion:'10.0',fileEncoding:'Cp1252',fileSeparator:'\\',
        sunArchDataModel:'64',sunDesktop:'windows',sunCpuIsalist:'amd64',
        javaLauncherPath:'launcher8182',javaRuntimeVersion:'11.0.10+9-LTS'}

        url = (EXTERN_URL_2 + '/ping/login');
        response =send_to_server(url,Net::HTTP::Post,true,true,login_body);
        jsn = json_parser(response.body);
        @ping_token = jsn["requestId"];
        Fiber.yield(response);
      end
    end
      return fiber;
  end

  def ping_fiber()#only on first ping auth needed/ or ip change
    fiber = Fiber.new do |auth|#true or false
      loop do
        ping_request_model = {requestId:"#{@ping_token}",
             lastResponseTime:"#{rand(400..1600)}",
             answer:"#{@answer}",userProcessModel:''}

        url = (EXTERN_URL_2 + '/ping/ping');
        response =
              send_to_server(url,Net::HTTP::Post,auth,true,ping_request_model);
        Fiber.yield(response);
      end
    end
    return fiber;
  end

  def list_fiber()
    fiber = Fiber.new do
      loop do
        url = (EXTERN_URL_2 + '/ping/list');
        response = send_to_server(url, Net::HTTP::Get,true,false,false);
        @list_json = json_parser(response.body);
        Fiber.yield(response)
      end
    end
    return fiber;
  end

  def test_fiber()
    fiber = Fiber.new do
      loop do
        url = (EXTERN_URL_2 + '/ping/test');
        response = send_to_server(url,Net::HTTP::Post,true,true,false);
                                                    #auth checksum body
        Fiber.yield(response);
      end
    end
    return fiber;
  end

  def encode_user_creds()
    fail_msg = "user credits fail, expected 4xl3xd:ldld6xl";
    raise fail_msg unless (@user_creds.size() == 18);
    @auth_id = Base64.urlsafe_encode64(@user_creds);
  end

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
    rescue *ALL_NET_HTTP_ERRORS => e
      print "\u{0a 1f691 20 20 20 1f692 20 20 20 1f691 20 20 20 0a}"#🚒
      print "#{e.class} occured at: #{Time.now}";
      print "\u{0a 1f692 20 20 20 1f691 20 20 20 1f692 20 20 20 0a}"#🚑
    end
  end

  def set_answer_delay
    Thread.new {
      20.times {print"\u{2588 2588 2588 20}"}
      print "#{Thread.current} gonna \u{1f6cc 0a}"#🛌
      sleep(rand(34..200));
      @answer = @question;
      20.times {print"\u{2588 2588 2588 20}"}
      print "#{Thread.current} #{@answer} set, done¡ \u{0a}";
    }
  end

  def check_presence_updated
    updated = false;
    begin
      stime = Time.parse(@list_json['presenceCheckList'][-1]['startTime']);#
      etime = Time.parse(@list_json['presenceCheckList'][-1]['endtime']);#
      if ( (stime.to_i)..(etime.to_i) ).include?(@check_time.to_i)
        updated = true;
      end
    rescue
      print "\u{1f691 20 20 20 1f692 20 20 20 1f691 20 20 20 0a}"#🚒
      pp @list_json;
      print "\u{1f692 20 20 20 1f691 20 20 20 1f692 20 20 20 0a}"#🚑
      return updated;
    end
    return updated;
  end

  def json_parser(str)
    begin
      JSON.parse(str);
    rescue
      print "\u{1f6a8 20 1f6a8 20 1f6a8 20}could not parse: #{str}\u{0a}"#🚨
      return nil;
    end
  end

  def check_login_success(login_response)#ping_token set or no
    login_response_body_parsed = json_parser(login_response.body);
    if (login_response.code=='200' && login_response_body_parsed && @ping_token)
      print "\u{0a 1f510 20}server replied HTTP-OK to login request\u{0a}";#🔐
      print "\u{1f6c2 20} #{@ping_token} is your 'requestId' for this session";#🛂
      return true;
    else
      print "login body json \u{1f52c 0a}"#🔬
      pp login_response_body_parsed;
      return false;
    end
  end

  def check_test_response(test_response)
    if (test_response.code=='200')
      print "\u{0a 1f4f6 20}server replied HTTP-OK to test request\u{0a}";#📶
      return true;
    else
      print "test to_hash \u{1f52c 0a}"#🔬
      pp test_response.to_hash();
      return false;
    end
  end

  private :send_to_server

end
