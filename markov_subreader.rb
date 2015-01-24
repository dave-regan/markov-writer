require 'redis'
require 'json'

dictionary_string = ""

Dir.foreach('subtitles') do |item|
	next if item == '.' or item == '..' or item == '.DS_Store'
	file = File.open("subtitles/#{item}", "r").each_line do |line|
		convertedline = line.encode('UTF-8', 'UTF-8', :invalid => :replace)
		if convertedline.length >= 1
			dictionary_string << convertedline unless !!(convertedline[0,1] =~ /[0-9]/)
		end	
	end
	file.close
end

dictionary_text = dictionary_string.downcase.gsub(/\{.*\}/, '').gsub(/[^a-z0-9\s\.\?\!]/, '').split(" ")

# puts dictionary_text

two_markov_dictionary = Array.new
three_markov_dictionary = Array.new

##### Depth 2 dictionary

for i in (0..(dictionary_text.length-1)) do
	# If the first word doesn't contain punctuation, then add the chain
	if /[^\.\?\!]/.match(dictionary_text[i][-1,1]) then
		two_markov_dictionary[i] = [dictionary_text[i], dictionary_text[i+1]]
	end
end

two_markov_dictionary.reject! { |x| x.to_s.empty? }

##### Depth 3 dictionary

for i in (0..(dictionary_text.length-2)) do
	# If the first word and second words don't contain punctuation, then add the chain
	if /[^\.\?\!]/.match(dictionary_text[i][-1,1]) && /[^\.\?\!]/.match(dictionary_text[i+1][-1,1]) then
		three_markov_dictionary[i] = [dictionary_text[i], dictionary_text[i+1], dictionary_text[i+2]]
	end
end

three_markov_dictionary.reject!{ |x| x.to_s.empty? }

#####

markov_hash = Hash.new
sorted_markov_hash = Hash.new
twice_sorted_markov_hash = Hash.new

two_markov_dictionary.each { |chain|
	# If starting word isn't already a key, create it with a value of empty array
	markov_hash[chain[0]] = Array.new if markov_hash[chain[0]].nil?
	# Add the second word as an element in the array
	markov_hash[chain[0]] << chain[1]
#	for i in 0..(three_markov_dictionary.length-1)
#		if (chain[0] == three_markov_dictionary[i][0]) && (chain[1] == three_markov_dictionary[i][1])
#			markov_hash[chain[0]][chain[1]] << [three_markov_dictionary[i][2]]
#		end
#	end
	}

markov_hash.each { |fword, fval|
	# Iterate over each element in the array, converting it into a hash with value equal to the total number of elements, then sort from most to least
	sorted_markov_hash[fword] = fval.each_with_object(Hash.new(0)) { |m, h| h[m] += 1 }.sort_by { |k, v| v }.reverse
	# Rewrite as a new hash with the first three elements
	sorted_markov_hash[fword] = Hash[sorted_markov_hash[fword].sort_by {|k, v| -v }[0..2]]
}

# Iterate over each two-word Markov chain and, if it matches a three-word chain, add the third word to the array
sorted_markov_hash.each { |fword, fval|
	fval.each { |sword, sval|
	sorted_markov_hash[fword][sword] = Array.new
		for i in 0..(three_markov_dictionary.length-2)
			if (fword == three_markov_dictionary[i][0]) && (sword == three_markov_dictionary[i][1])
				sorted_markov_hash[fword][sword] << three_markov_dictionary[i][2]
			end
		end
	}
}

sorted_markov_hash.each { |fword, fval|
	twice_sorted_markov_hash[fword] = Hash.new
	fval.each { |sword, sval|
		# Iterate over each element in the array, converting it into a hash with value equal to the total number of elements, then sort from most to least
		twice_sorted_markov_hash[fword][sword] = sval.each_with_object(Hash.new(0)) { |m, h| h[m] += 1 }.sort_by { |k, v| v }.reverse 
		# Rewrite as a new hash with the first three elements
		twice_sorted_markov_hash[fword][sword] = Hash[twice_sorted_markov_hash[fword][sword].sort_by {|k, v| -v }[0..2]]
		# Rewrite as an array
		twice_sorted_markov_hash[fword][sword] = twice_sorted_markov_hash[fword][sword].map { |k, v| k }.reject { |x| x.empty? }
	}
}

redis = Redis.new(:url => 'redis://redistogo:f9ee22f5c4836345ebd34fc04c0c7621@jack.redistogo.com:11378/')

redis.set("schwarzenegger", twice_sorted_markov_hash.to_json)
