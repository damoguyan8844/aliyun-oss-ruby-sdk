class Fibr
  @@fs = []   # a stack of fibers corresponding to calls of 'resume'

  RB_FILTER_STATUS = {
         :FIBER_NONE => 0,
         :FIBER_KILLED => 1,
         :FIBER_CREATED => 3,
         :FIBER_RUNNING => 4,
         :FIBER_STOPPED => 5};

  def initialize(&block)
    @k = lambda(&block)         # lambda makes 'return' work as expected
    @status = RB_FILTER_STATUS[:FIBER_CREATED]
  end

  def resume(*xs)

    if @status == RB_FILTER_STATUS[:FIBER_KILLED]
      #raise "dead fiber called"
      return
    elsif @status == RB_FILTER_STATUS[:FIBER_RUNNING]
      #raise "double resume"
      return
    end

    @@fs.push(self)
    jump(xs)                    # jumping into fiber
    #if @status != RB_FILTER_STATUS[:FIBER_KILLED]
    #  @status = RB_FILTER_STATUS[:FIBER_STOPPED];
    #end
  end

  def alive?
    @status > RB_FILTER_STATUS[:FIBER_KILLED]
  end

  def self.current
    @@fs.last
  end

  def self.yield(*xs)
    f = @@fs.pop
    f && f.send(:jump, xs)      # jumping out of fiber
  end

  private
  def jump(xs)
    callcc { |k|
      destination = @k
      @k = k
      @status = RB_FILTER_STATUS[:FIBER_RUNNING]
      destination.call(*xs)
      @status = RB_FILTER_STATUS[:FIBER_STOPPED]
      @@fs.pop
      @k.call                 # return from the last 'resume'
    }
  end
end
Fiber = Fibr if RUBY_VERSION < "1.9"