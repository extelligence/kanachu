class WelcomeController < ApplicationController
  def index
    @timetables = Timetables.get_bus_now?
  end
end
