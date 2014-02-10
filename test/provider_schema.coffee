# OAuth daemon
# Copyright (C) 2013 Webshell SAS
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

module.exports =
	id: "https://oauth.io/provider-schema#"
	"$schema": "http://json-schema.org/draft-04/schema#"
	title: "OAuth.io provider's OAuths description"
	type: "object"
	additionalProperties: false
	properties:
		"name":
			description: "The provider's displayed name"
			type: "string"
		"url":
			description: "The base absolute url to use in sub-parts"
			type: "string"
		"desc":
			description: "Description of the API provider"
			type: "string"
		"oauth1":
			description: "The OAuth 1.0/1.0a description"
			type: "object"
			additionalProperties: false
			required: ["request_token", "authorize", "access_token"]
			properties:
				"request_token":
					description: "The request token endpoint for OAuth 1"
					oneOf: [
						{type: "string"},
						{
							type: "object"
							additionalProperties: false
							required: ["url"]
							properties:
								"url":
									type: "string"
								"method":
									type: "string"
									enum: ["get", "post"]
								"format":
									description: "force the response content type"
									type: "string"
									enum: ["json", "url", "application/json", "application/x-www-form-urlencoded"]
								"query":
									type: "object"
								"headers":
									type: "object"
						}
					]
				"authorize":
					description: "The authorize endpoint for OAuth 1"
					oneOf: [
						{type: "string"},
						{
							type: "object"
							additionalProperties: false
							required: ["url"]
							properties:
								"url":
									type: "string"
								"ignore_verifier":
									description: "Set ignore_verifier to true if you are using the old OAuth 1.0"
									type: "boolean"
								"query":
									type: "object"
								"extra":
									type: "array"
									items:
										type: "string"
						}
					]
				"access_token":
					description: "The access token endpoint for OAuth 1"
					oneOf: [
						{type: "string"},
						{
							type: "object"
							additionalProperties: false
							required: ["url"]
							properties:
								"url":
									type: "string"
								"method":
									type: "string"
									enum: ["get", "post"]
								"format":
									description: "force the response content type"
									type: "string"
									enum: ["json", "url", "application/json", "application/x-www-form-urlencoded"]
								"query":
									type: "object"
								"headers":
									type: "object"
								"extra":
									type: "array"
									items:
										type: "string"
						}
					]
				"request":
					description: "The authorizing API requests description"
					oneOf: [
						{type: "string"},
						{type: "boolean"},
						{
							type: "object"
							additionalProperties: false
							properties:
								"url":
									type: "string"
								"required":
									description: "used fields from authorization (appart oauth_*)"
									type: "array"
									items:
										type: "string"
								"query":
									type: "object"
								"headers":
									type: "object"
						}
					]
				"parameters":
					$ref: "#/definitions/parameters"
					description: "Parameters used only in OAuth 1"
		"oauth2":
			description: "The OAuth 2.0 description"
			type: "object"
			additionalProperties: false
			required: ["authorize", "access_token"]
			properties:
				"authorize":
					description: "The authorize endpoint for OAuth 2"
					oneOf: [
						{type: "string"},
						{
							type: "object"
							additionalProperties: false
							required: ["url"]
							properties:
								"url":
									type: "string"
								"extra":
									type: "array"
									items:
										type: "string"
								"query":
									type: "object"
						}
					]
				"access_token":
					description: "The access token endpoint for OAuth 2"
					oneOf: [
						{type: "string"},
						{
							type: "object"
							additionalProperties: false
							required: ["url"]
							properties:
								"url":
									type: "string"
								"method":
									type: "string"
									enum: ["get", "post"]
								"extra":
									type: "array"
									items:
										type: "string"
								"format":
									description: "force the response content type"
									type: "string"
									enum: ["json", "url", "application/json", "application/x-www-form-urlencoded"]
								"query":
									type: "object"
								"headers":
									type: "object"
						}
					]
				"refresh":
					description: "The refresh token endpoint for OAuth 2"
					oneOf: [
						{type: "string"},
						{
							type: "object"
							additionalProperties: false
							required: ["url"]
							properties:
								"url":
									type: "string"
								"method":
									type: "string"
									enum: ["get", "post"]
								"format":
									description: "force the response content type"
									type: "string"
									enum: ["json", "url", "application/json", "application/x-www-form-urlencoded"]
								"query":
									type: "object"
								"headers":
									type: "object"
						}
					]
				"revoke":
					description: "The revoke application endpoint for OAuth 2"
					oneOf: [
						{type: "string"},
						{
							type: "object"
							additionalProperties: false
							required: ["url"]
							properties:
								"url":
									type: "string"
								"query":
									type: "object"
								"method":
									type: "string"
									enum: ["get", "post", "delete"]
								"headers":
									type: "object"
						}
					]
				"request":
					description: "The authorizing API requests description"
					oneOf: [
						{type: "string"},
						{type: "boolean"},
						{
							type: "object"
							additionalProperties: false
							properties:
								"url":
									type: "string"
								"required":
									description: "used fields from authorization (appart token)"
									type: "array"
									items:
										type: "string"
								"query":
									type: "object"
								"cors":
									description: "Set to true if the API accepts CORS requests. Defaults to false"
									type: "boolean"
								"headers":
									type: "object"
						}
					]
				"parameters":
					$ref: "#/definitions/parameters"
					description: "Parameters used only in OAuth 2"
		"parameters":
			$ref: "#/definitions/parameters"
			description: "Global parameters used in both OAuth 1 and 2"
		"href":
			description: "Useful links related to the provider"
			type: "object"
			properties:
				"provider":
					description: "An url to the provider's site"
					type: "string"
					format: "uri"
				"keys":
					description: "An url to the app creation"
					type: "string"
					format: "uri"
				"apps":
					description: "An url to the existing apps list"
					type: "string"
					format: "uri"
				"docs":
					description: "An url to the authentication documentation"
					type: "string"
					format: "uri"
	definitions:
		"parameters":
			description: "Parameters used in both OAuth 1 and 2"
			type: "object"
			patternProperties:
				"^.*$":
					oneOf: [{
						type: "string"
						enum: ["string"]
					}, {
						type: "object"
						additionalProperties: false
						properties:
							"values":
								type: "object"
								patternProperties:
									"^.*$":
										type: "string"
							"scope":
								description: "if set to 'public', this parameter can be use in cors requests"
								type: "string"
								enum: ["public"]
							"cardinality":
								type: "string"
								enum: ["*", "1"]
							"separator":
								type: "string"
							"type":
								type: "string"
								enum: ["string"]
					}]
	required: ["name", "url"]
	additionalProperties: false