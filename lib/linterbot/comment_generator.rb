module Linterbot

  class CommentGenerator

    attr_accessor :filename
    attr_accessor :commit
    attr_accessor :pull_request_file_patch
    attr_accessor :commits_count_for_file

    def initialize(filename, commit, pull_request_file_patch, commits_count_for_file)
      @filename = filename
      @commit = commit
      @pull_request_file_patch = Patch.new(pull_request_file_patch)
      @commits_count_for_file = commits_count_for_file
    end

    def generate_comments(hints)
      hints.map { |hint| generate_comment_for_hint(hint) }
        .select { |comment| comment != nil }
    end

    def generate_comment_for_hint(hint)
      patch_line_number = comment_position_for_hint(hint)
      if patch_line_number
        Comment.new(sha: commit.sha, patch_line_number: patch_line_number, hint: hint)
      end
    end

    def file
      @file ||= find_file
    end

    private

      def find_file
        file_index = commit.files.find_index { |file| file.filename == filename }
        commit.files[file_index]
      end

      def new_file?
        file.status == "added"
      end

      def modified_file?
        file.status == "modified"
      end

      def file_patch
        Patch.new(file.patch)
      end

      def included_in_file_patch?(hint)
        file_patch.included_in_patch?(hint)
      end

      def pull_request_file_patch_line_number(hint)
        pull_request_file_patch
          .additions_ranges_for_hint(hint)
          .map { |diff_range, line_number|  line_number + (hint.line - diff_range.first) + 1 }
          .first
      end

      def comment_position_for_hint(hint)
        if new_file? && commits_count_for_file == 1
          hint.line
        elsif modified_file? && included_in_file_patch?(hint)
          pull_request_file_patch_line_number(hint)
        end
      end

  end

end
