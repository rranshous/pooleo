require 'sinatra'
require 'json'

get '/:sleeptime' do |sleeptime|
  sleeptime = sleeptime.to_i
  sleep(sleeptime)
  content_type :json
  return { success: true, sleep: sleeptime }.to_json
end
