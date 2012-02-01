require "spec_helper"

describe "Queue Priority" do

  before(:each) do
    Resque.redis.flushall
  end

  context "basic resque behavior still works" do

    it "can work on multiple queues" do
      Resque::Job.create(:high, SomeJob)
      Resque::Job.create(:critical, SomeJob)

      worker = Resque::Worker.new(:critical, :high)

      worker.process
      Resque.size(:high).should == 1
      Resque.size(:critical).should == 0

      worker.process
      Resque.size(:high).should == 0
    end

    it "can work on all queues" do
      Resque::Job.create(:high, SomeJob)
      Resque::Job.create(:critical, SomeJob)
      Resque::Job.create(:blahblah, SomeJob)

      worker = Resque::Worker.new("*")

      worker.work(0)
      Resque.size(:high).should == 0
      Resque.size(:critical).should == 0
      Resque.size(:blahblah).should == 0
    end

    it "processes * queues in alphabetical order" do
      Resque::Job.create(:high, SomeJob)
      Resque::Job.create(:critical, SomeJob)
      Resque::Job.create(:blahblah, SomeJob)

      worker = Resque::Worker.new("*")

      worker.work(0) do |job|
        Resque.redis.rpush("processed_queues", job.queue)
      end

      Resque.redis.lrange("processed_queues", 0, -1).should == %w( high critical blahblah ).sort
    end

    it "should pass lint" do
      Resque::Plugin.lint(Resque::Plugins::QueuePriority)
    end

  end

  context "queue patterns" do

    before(:each) do
      Resque.watch_queue("high_x")
      Resque.watch_queue("foo")
      Resque.watch_queue("high_y")
      Resque.watch_queue("superhigh_z")
    end

    it "can specify simple queues" do
      worker = Resque::Worker.new("foo")
      worker.queues.should == ["foo"]

      worker = Resque::Worker.new("foo", "bar")
      worker.queues.should == ["foo", "bar"]
    end

    it "can specify simple wildcard" do
      worker = Resque::Worker.new("*")
      worker.queues.should == ["foo", "high_x", "high_y", "superhigh_z"]
    end

    it "should pick up all queues with default priority" do
      Resque.priority_buckets = [{'pattern' => 'default', 'fairly' => false}]
      worker = Resque::Worker.new("*")
      worker.queues.should == ["foo", "high_x", "high_y", "superhigh_z"]
    end

    it "should pick up all queues fairly" do
      # do a bunch to reduce likyhood of random match causing test failure
      50.times {|i| Resque.watch_queue("auto_#{i}") }
      Resque.priority_buckets = [{'pattern' => 'default', 'fairly' => true}]
      worker = Resque::Worker.new("*")
      worker.queues.should_not == Resque.queues.sort
      worker.queues.sort.should == Resque.queues.sort
    end

    it "should prioritize simple pattern" do
      Resque.priority_buckets = [{'pattern' => 'superhigh_z', 'fairly' => false},
                                 {'pattern' => 'default', 'fairly' => false}]
      worker = Resque::Worker.new("*")
      worker.queues.should == ["superhigh_z", "foo", "high_x", "high_y"]
    end

    it "should prioritize multiple simple patterns" do
      Resque.priority_buckets = [{'pattern' => 'superhigh_z', 'fairly' => false},
                                 {'pattern' => 'default', 'fairly' => false},
                                 {'pattern' => 'foo', 'fairly' => false}]
      worker = Resque::Worker.new("*")
      worker.queues.should == ["superhigh_z", "high_x", "high_y", "foo"]
    end

    it "should prioritize simple wildcard pattern" do
      Resque.priority_buckets = [{'pattern' => 'high*', 'fairly' => false},
                                 {'pattern' => 'default', 'fairly' => false}]
      worker = Resque::Worker.new("*")
      worker.queues.should == ["high_x", "high_y", "foo", "superhigh_z"]
    end

    it "should prioritize simple wildcard pattern with correct matching" do
      Resque.priority_buckets = [{'pattern' => '*high*', 'fairly' => false},
                                 {'pattern' => 'default', 'fairly' => false}]
      worker = Resque::Worker.new("*")
      worker.queues.should == ["high_x", "high_y", "superhigh_z", "foo"]
    end
    
    it "should prioritize negation patterns" do
      Resque.priority_buckets = [{'pattern' => 'high*,!high_x', 'fairly' => false},
                                 {'pattern' => 'default', 'fairly' => false}]
      worker = Resque::Worker.new("*")
      worker.queues.should == ["high_y", "foo", "high_x", "superhigh_z"]
    end

    it "should not be affected by standalone negation patterns" do
      Resque.priority_buckets = [{'pattern' => '!high_x', 'fairly' => false},
                                 {'pattern' => 'default', 'fairly' => false}]
      worker = Resque::Worker.new("*")
      worker.queues.should == ["foo", "high_x", "high_y", "superhigh_z"]
    end

    it "should allow multiple inclusive patterns" do
      Resque.priority_buckets = [{'pattern' => 'high_x, superhigh*', 'fairly' => false},
                                 {'pattern' => 'default', 'fairly' => false}]
      worker = Resque::Worker.new("*")
      worker.queues.should == ["high_x", "superhigh_z", "foo", "high_y"]
    end

    it "should prioritize fully inclusive wildcard pattern" do
      Resque.priority_buckets = [{'pattern' => '*high*', 'fairly' => false},
                                 {'pattern' => 'default', 'fairly' => false}]
      worker = Resque::Worker.new("*")
      worker.queues.should == ["high_x", "high_y", "superhigh_z", "foo"]
    end

    it "should handle empty default match" do
      Resque.priority_buckets = [{'pattern' => '*', 'fairly' => false},
                                 {'pattern' => 'default', 'fairly' => false}]
      worker = Resque::Worker.new("*")
      worker.queues.should == ["foo", "high_x", "high_y", "superhigh_z"]
    end

    it "should pickup wildcard queues fairly" do
      others = 5.times.collect {|i| "other#{i}" }
      others.map {|o| Resque.watch_queue(o)}

      Resque.priority_buckets = [{'pattern' => 'other*', 'fairly' => true},
                                 {'pattern' => 'default', 'fairly' => false}]
      worker = Resque::Worker.new("*")
      worker.queues.size
      worker.queues[0..4].sort.should == others.sort
      worker.queues[5..-1].should == ["foo", "high_x", "high_y", "superhigh_z"]
      worker.queues.should_not == others.sort + ["foo", "high_x", "high_y", "superhigh_z"]
    end

  end

  context "queue priority accessors" do

    it "can lookup a default priority" do
      Resque.priority_buckets.should == [{'pattern' => 'default'}]
    end

    it "can set priorities" do
      Resque.priority_buckets = [{'pattern' => 'foo', 'fairly' => 'false'}]
      Resque.priority_buckets.should == [{'pattern' => 'foo', 'fairly' => 'false'},
                                         {'pattern' => 'default'}]
    end

    it "can set priorities including default" do
      Resque.priority_buckets = [{'pattern' => 'foo', 'fairly' => false},
                                 {'pattern' => 'default', 'fairly' => false},
                                 {'pattern' => 'bar', 'fairly' => true}]
      Resque.priority_buckets.should == [{'pattern' => 'foo', 'fairly' => false},
                                         {'pattern' => 'default', 'fairly' => false},
                                         {'pattern' => 'bar', 'fairly' => true}]
    end

  end

end
