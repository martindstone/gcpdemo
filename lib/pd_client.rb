require 'httparty'

module PdClient
	def auth_str_for_token(token)
		if /^[0-9a-f]{64}$/.match?(token)
			"Bearer #{token}"
		else
			"Token token=#{token}"
		end
	end

	def get(token, endpoint, query: nil, addheaders: nil)
		auth = auth_str_for_token(token)
		headers = {
			'Accept' => 'application/vnd.pagerduty+json;version=2',
			'Authorization' => auth
		}
		if not addheaders.nil?
			headers = headers.merge(addheaders)
		end
		response = HTTParty.get(
			"https://api.pagerduty.com/#{endpoint}",
				headers: headers,
				query: query,
				format: :json
			)
		response.parsed_response
	end

	def delete(token, endpoint, addheaders: nil)
		auth = auth_str_for_token(token)
		headers = {
			'Accept' => 'application/vnd.pagerduty+json;version=2',
			'Authorization' => auth
		}
		if not addheaders.nil?
			headers = headers.merge(addheaders)
		end
		response = HTTParty.delete(
			"https://api.pagerduty.com/#{endpoint}",
				headers: headers,
				format: :json
			)
		response.parsed_response
	end

	def post(token, from, endpoint, json, addheaders: nil)
		auth = auth_str_for_token(token)
		headers = {
			'Accept' => 'application/vnd.pagerduty+json;version=2',
			'Authorization' => auth,
			'Content-Type' => 'application/json; charset=utf-8'
		}
		if not from.nil?
			headers['From'] = from
		end
		if not addheaders.nil?
			headers = headers.merge(addheaders)
		end
		response = HTTParty.post(
			"https://api.pagerduty.com/#{endpoint}",
				headers: headers,
				body: json,
				format: :json
			)
		response.parsed_response
	end

	def put(token, from, endpoint, json, addheaders: nil)
		auth = auth_str_for_token(token)
		headers = {
			'Accept' => 'application/vnd.pagerduty+json;version=2',
			'Authorization' => auth,
			'Content-Type' => 'application/json; charset=utf-8'
		}
		if not from.nil?
			headers['From'] = from
		end
		if not addheaders.nil?
			headers = headers.merge(addheaders)
		end
		response = HTTParty.put(
			"https://api.pagerduty.com/#{endpoint}",
				headers: headers,
				body: json,
				format: :json
			)
		response.parsed_response
	end

	def fetch(token, endpoint, query: {}, addheaders: nil)
		more = true
		if query.nil?
			query = {}
		end
		query = query.merge({offset: 0})
		fetched_data = []
		while more
			page = get(token, endpoint, query: query, addheaders: addheaders)
			unless page.respond_to?("has_key?")
				AppLogger.error({
					"message": "Get did not return a hash in fetch #{endpoint}: #{page}"
				})
				return nil
			end
			if page.has_key?("error")
				AppLogger.error({
					"message": "Error in fetch #{endpoint}: #{page}"
				})
				return nil
			end
			unless page.has_key?(endpoint)
				AppLogger.error({
					"message": "Page doesn't have endpoint element in fetch #{endpoint}: #{page}"
				})
				return nil
			end
			fetched_data += page[endpoint]
			if page["more"]
				query[:offset] += page["limit"]
			end
			more = page["more"]
		end
		fetched_data
	end

	def fetch_services(token, query: {})
		fetch(token, "services", query: query)
	end

	def fetch_users(token, query: {})
		fetch(token, "users", query: query)
	end

	def me(token)
		get(token, "/users/me")["user"]
	end

	def domain(token)
		me(token)["html_url"].split(/[\/\.]+/)[1]
	end

	def get_user(token, user_id)
		get(token, "users/#{user_id}")
	end

	def get_incident(token, incident_id)
		get(token, "incidents/#{incident_id}")
	end

	def update_incident(token, from, incident_id, status)
		body = {
			incident: {
				type: "incident_reference",
				status: status
			}
		}
		put(token, from, "incidents/#{incident_id}", JSON.generate(body))
	end

	def ack_incident(token, from, incident_id)
		update_incident(token, from, incident_id, "acknowledged")
	end

	def resolve_incident(token, from, incident_id)
		update_incident(token, from, incident_id, "resolved")
	end
end