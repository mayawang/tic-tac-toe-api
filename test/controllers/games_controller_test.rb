require 'test_helper'

class GamesControllerTest < ActionController::TestCase
  def setup
    @controller = GamesController.new
  end

  class General < GamesControllerTest
    test "GamesController should exist" do
      assert GamesController
    end
  end

  class Actions < GamesControllerTest
    def self.base_tests(verb, &request_block)
      test "should accept #{verb} requests" do
        assert self.instance_eval(&request_block)
      end

      test "should return success" do
        self.instance_eval(&request_block)
        assert_response :success
      end
    end

    def self.base_get_tests(&request_block)
      base_tests("GET", &request_block)

      test "should return JSON" do
        self.instance_eval(&request_block)
        assert_equal Mime[:json].to_s, response.content_type
      end
    end

    def parsed_body
      JSON.parse(response.body)
    end
  end

  class IndexAction < Actions
    base_get_tests do
      get :index
    end

    test "should return a list" do
      get :index

      assert_kind_of Array, parsed_body
    end

    test "should return a list with entries for each Game" do
      games = create_list(:game, rand(1..100))

      get :index

      assert_equal games.length, parsed_body.length
    end

    test "should return a list with Game summary data" do
      create_list(:game, 10)

      get :index

      parsed_body.each do |game|
        assert_kind_of Hash, game

        fields = game.keys.map(&:to_sym).to_set
        assert_equal Game::SUMMARY_FIELDS.to_set, fields, "Invalid summary fields for game ##{game["id"] || 'null'}"
      end
    end
  end

  class ShowAction < Actions
    def setup
      @game = create(:game)
    end

    base_get_tests do
      get :show, params: {id: @game.id}
    end

    test "should return a hash" do
      get :show, params: {id: @game.id}

      assert_kind_of Hash, parsed_body
    end

    test "should return a hash with Game details data" do
      get :show, params: {id: @game.id}

      game = parsed_body
      fields = game.keys.map(&:to_sym).to_set
      assert_equal Game::DETAILS_FIELDS.to_set, fields, "Invalid details fields for game ##{game["id"] || 'null'}"
    end

    test "should return the requested Game" do
      get :show, params: {id: @game.id}

      # Check that the IDs match
      assert_equal @game.id, parsed_body["id"]

      # Check that all of the other fields match
      Game::DETAILS_FIELDS.reject{|f|f == :id}.map(&:to_s).each do |field|
        assert_equal @game.data[field], parsed_body[field], "Mismatch in returned data for game ##{@game.id}, field: #{field}"
      end
    end

    test "should return Not Found for non-existent Game" do
      get :show, params: {id: @game.id + 1}

      assert_response :missing
    end
  end
end
