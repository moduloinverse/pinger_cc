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

  # in means of REST api terminology, should be called userPingToken,
  # cuz its temporary.
  # requestId 🌩329 X-Request-ID

  attr_accessor :user_creds, :auth_id, :ping_token;
  attr_accessor :answer, :question, :check_time;
  attr_accessor :list_json;

  def login_fiber()
    fiber = Fiber.new do
      login_body = {userHome:"C:\\User\\#{@user_creds.split(":")[0]}",
      userDomain:"DESKTOP-#{@user_creds.split(":")[0]}",
      userCountry:'DE',userLanguage:'de',osArch:'amd64',osName:'Windows 10',
      osVersion:'10.0',fileEncoding:'Cp1252',fileSeparator:'\\',
      sunArchDataModel:'64',sunDesktop:'windows',sunCpuIsalist:'amd64',
      javaLauncherPath:'launcher8182',javaRuntimeVersion:'11.0.10+9-LTS'}

      url = URI(EXTERN_URL_2 + '/ping/login');
      connection = Net::HTTP.new(url.host, url.port);
      connection.use_ssl = true;
      request = Net::HTTP::Post.new(url);
      add_request_fields(request,true,login_body);
      response = connection.request(request);
      jsn = json_parser(response.body);
      @ping_token = jsn["requestId"];
      Fiber.yield(response);
    end
      return fiber;
  end

  def ping_fiber()
    fiber = Fiber.new do
      loop do
        ping_request_model = {requestId:"#{@ping_token}",
             lastResponseTime:"#{rand(400..1600)}",
             answer:"#{@answer}",userProcessModel:''}

        url = URI(EXTERN_URL_2 + '/ping/ping');
        connection = Net::HTTP.new(url.host, url.port);
        connection.use_ssl = true;
        request = Net::HTTP::Post.new(url);
        add_request_fields(request,true,ping_request_model);
        response = connection.request(request);
        Fiber.yield(response);
      end
    end
    return fiber;
  end

  def list_fiber()
    fiber = Fiber.new do
      loop do
        url = URI(EXTERN_URL_2 + '/ping/list');
        connection = Net::HTTP.new(url.host, url.port);
        connection.use_ssl = true;
        request = Net::HTTP::Get.new(url);
        add_request_fields(request);
        response = connection.request(request);
        @list_json = json_parser(response.body);
        Fiber.yield(response)
      end
    end
    return fiber;
  end

  def test_fiber()#only checksum neede
    fiber = Fiber.new do
      url = URI(EXTERN_URL_2 + '/ping/test');
      connection = Net::HTTP.new(url.host, url.port);
      connection.use_ssl = true;
      request = Net::HTTP::Post.new(url);
      add_request_fields(request,true);
      response = connection.request(request);
      Fiber.yield(response);
    end
    return fiber;
  end

  def encode_user_creds()
    fail_msg = "user credits fail, expected 4xl3xd:ldld6xl";
    raise fail_msg unless (@user_creds.size() == 18);
    @auth_id = Base64.urlsafe_encode64(@user_creds);
  end

  def add_request_fields(request,checksum=nil,body=nil)
    request['authorization'] = 'Basic ' + @auth_id;
    request['checksum'] = CHECKSUM if checksum;
    request['Content-Type'] = 'application/json';
    request['User-Agent'] = 'Swagger-Codegen/1.2.0-SNAPSHOT/java';
    request.body = body.to_json if body
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


end
