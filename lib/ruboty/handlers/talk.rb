require "docomoru"

module Ruboty
  module Handlers
    class Talk < Base
      NAMESPACE = "alias"

      env :DOCOMO_API_KEY, "Pass DoCoMo API KEY"
      env :DOCOMO_CHARACTER_ID, "Character ID to be passed as t parameter", optional: true

      on(
        /(?<body>.+)/,
        description: "Talk with you if given message didn't match any other handlers",
        missing: true,
        name: "talk",
      )

      def talk(message)
        @name = message.from_name
        response = client.create_dialogue(message[:body], params)
        response_body = JSON.parse(response.body.force_encoding("utf-8"))
        brain[@name]["mode"] = response_body["command"]
        message.reply(response_body["systemText"]["utterance"])
      rescue Exception => e
        Ruboty.logger.error(%<Error: #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}>)
      end

      private

      def client
        @client ||= Docomoru::Client.new(api_key: ENV["DOCOMO_API_KEY"])
      end

      def params
        {
          clientData:{
            option:{
              mode: mode,
              t: "kansai"
            }
          }
        }.reject do |key, value|
          value.nil?
        end
      end

      def brain
        robot.brain.data[NAMESPACE] ||= {}
      end

      def mode
        !brain[@name].nil? && brain[@name]["mode"] == "eyJtb2RlIjoic3J0ciJ9" ? "srtr" : "dialog"
      end
    end
  end
end
