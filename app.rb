require 'sinatra'
require 'redis'
require 'json'

get '/markov.json' do

	callback = params.delete('callback') # jsonp
	json = {:resp => ReturnResp(params) }.to_json

	if callback
      content_type :js
      response = "#{callback}(#{json})" 
    else
      content_type :json
      response = json
    end
    
    response

end

def ReturnResp(params)

	redis = Redis.new(:url => 'redis://redistogo:f9ee22f5c4836345ebd34fc04c0c7621@jack.redistogo.com:11378/')

	if params[:dictionary].nil?
		return "no dictionary defined"
	else
		dictionary = JSON.parse(redis.get(params[:dictionary]))
	end

	# dictionary = {"I" => {"am" => ["spartacus", "leeroy", "spartacallous"], "love" => ["candy", "breakfast", "spartacus"]}, "You" => {"am" => ["spartapoor"], "complete" => ["me", "idiot", "tetris"], "are" => ["yourself"]}}

	# two-chain hash for the best results (matches previous word and current word), one-chain hash for backup (matches current word only)
	resp = { 	
				:two_chainz => {},
				:one_chain => {}
			}

	dictionary.each do |firstword, firstarray|
		firstarray.each do |secondword, secondarray|
			case params[:partial]
					when "true"
						# A match on first and a partial on second is great...
						if params[:w2] == secondword[0, params[:w2].length] && params[:w1] == firstword
							secondarray.each do |thirdword|
								resp[:two_chainz][secondword].nil? ? (resp[:two_chainz][secondword] = [thirdword]) : (resp[:two_chainz][secondword] << thirdword)
							end
						# But a partial match on just the second is OK
						elsif params[:w2] == secondword[0, params[:w2].length]
							secondarray.each do |thirdword|
								resp[:one_chain][secondword].nil? ? (resp[:one_chain][secondword] = [thirdword]) : (resp[:one_chain][secondword] << thirdword)
							end
						end
					when "false"
						# A match on first and second is great...
						if params[:w2] == secondword && params[:w1] == firstword
							secondarray.each do |thirdword|
								resp[:two_chainz][secondword].nil? ? (resp[:two_chainz][secondword] = [thirdword]) : (resp[:two_chainz][secondword] << thirdword)
							end
						# But a match on just the second is OK
						elsif params[:w2] == secondword
							secondarray.each do |thirdword|
								resp[:one_chain][secondword].nil? ? (resp[:one_chain][secondword] = [thirdword]) : (resp[:one_chain][secondword] << thirdword)
							end
						end
			end
		end
	end

	resp.each do |firstword, firstarray|
		firstarray.each do |secondword, secondarray|
			resp[firstword][secondword].uniq!
		end
	end

	return resp

end