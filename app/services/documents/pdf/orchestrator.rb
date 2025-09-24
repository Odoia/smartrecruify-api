# frozen_string_literal: true

module Documents
  module Pdf
    # app/services/documents/pdf/orchestrator.rb
    class Orchestrator
      def initialize(file:, user:, include_catalog: true)
        @file            = file
        @user            = user
        @include_catalog = include_catalog
      end

      def call
        jpeg_paths = ToJpeg.new(file: file).call
        prompt     = AiPromptBuilder.new(
          images: jpeg_paths,
          user: user,
          course_catalog: course_catalog,
          pages_count: jpeg_paths.size
        ).call
        raw_json   = AiCaller.new(prompt: prompt).call

        Documents::Sanitize.new(payload: raw_json).call
      end

      private

      attr_reader :file, :user, :include_catalog

      def course_catalog
        return [] unless include_catalog
        @course_catalog ||= Education::CourseEnrollments::List.new.call
      end
    end
  end
end
