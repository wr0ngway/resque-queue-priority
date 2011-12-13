ENV['RACK_ENV'] = 'test'

require 'spec_helper'
require 'rack'
require 'rack/test'
require 'resque/server'
require 'resque-queue-priority-server'

Sinatra::Base.set :environment, :test
# ::Test::Unit::TestCase.send :include, Rack::Test::Methods


describe "Queue Priority pages" do
  include Rack::Test::Methods

  def app
    @app ||= Resque::Server.new
  end

  before(:each) do
    Resque.redis.flushall
  end

  context "existence in application" do

    it "should respond to it's url" do
      get "/queuepriority"
      last_response.should be_ok
    end

    it "should display its tab" do
      get "/overview"
      last_response.body.should include "<a href='/queuepriority'>QueuePriority</a>"
    end

  end

  context "show queue priority table" do

    before(:each) do
      Resque.priority_buckets = [{'pattern' => 'foo', 'fairly' => false},
                                 {'pattern' => 'default', 'fairly' => false},
                                 {'pattern' => 'bar', 'fairly' => true}]

    end

    it "should shows pattern input fields" do
      get "/queuepriority"

      last_response.body.should match /<input type="text" id="input-0-pattern" name="priorities\[\]\[pattern\]" value="foo"/
      last_response.body.should match /<input type="text" id="input-1-pattern" name="priorities\[\]\[pattern\]" value="default"/
      last_response.body.should match /<input type="text" id="input-2-pattern" name="priorities\[\]\[pattern\]" value="bar"/
    end

    it "should show fairly checkboxes" do
      get "/queuepriority"

      last_response.body.should match /<input type="checkbox" id="input-0-fairly" name="priorities\[\]\[fairly\]" value="true" *\/>/
      last_response.body.should match /<input type="checkbox" id="input-1-fairly" name="priorities\[\]\[fairly\]" value="true" *\/>/
      last_response.body.should match /<input type="checkbox" id="input-2-fairly" name="priorities\[\]\[fairly\]" value="true" checked *\/>/
    end

  end

  context "edit links" do

    before(:each) do
      Resque.priority_buckets = [{'pattern' => 'foo', 'fairly' => false},
                                 {'pattern' => 'default', 'fairly' => false},
                                 {'pattern' => 'bar', 'fairly' => true}]

    end

    it "should show remove link for queue" do
      get "/queuepriority"

      last_response.body.should match /<a href="#remove"/
    end

    it "should show up link for queue" do
      get "/queuepriority"

      last_response.body.should match /<a href="#up"/
    end

    it "should show down link for queue" do
      get "/queuepriority"

      last_response.body.should match /<a href="#down"/
    end

  end

  context "form to edit queues" do

    it "should have form to edit queues" do
      get "/queuepriority"

      last_response.body.should match /<form action="http:\/\/example.org\/queuepriority"/
    end

    it "should update queues" do
      Resque.priority_buckets.should == [{'pattern' => 'default'}]

      post "/queuepriority", {'priorities' => [{"pattern" => "foo"},
                                              {"pattern" => "default"},
                                              {"pattern" => "bar", "fairly" => "true"}]}

      last_response.should be_redirect
      last_response['Location'].should match /queuepriority/
      Resque.priority_buckets.should == [{"pattern" => "foo"},
                                         {"pattern" => "default"},
                                         {"pattern" => "bar", "fairly" => "true"}]
    end

  end

end
