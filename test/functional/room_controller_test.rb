require File.dirname(__FILE__) + '/../test_helper'
require 'room_controller'

# Re-raise errors caught by the controller.
class RoomController; def rescue_action(e) raise e end; end

class RoomControllerTest < Test::Unit::TestCase
  def setup
    @controller = RoomController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
