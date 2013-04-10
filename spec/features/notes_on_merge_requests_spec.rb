require 'spec_helper'

describe "On a merge request", js: true do
  let!(:project) { create(:project_with_code) }
  let!(:merge_request) { create(:merge_request, project: project) }

  before do
    login_as :user
    project.team << [@user, :master]

    visit project_merge_request_path(project, merge_request)
  end

  subject { page }

  describe "the note form" do
    it 'should be valid' do
      should have_css(".js-main-target-form", visible: true, count: 1)
      find(".js-main-target-form input[type=submit]").value.should == "Add Comment"
      within(".js-main-target-form") { should_not have_link("Cancel") }
      within(".js-main-target-form") { should have_css(".js-note-preview-button", visible: false) }
    end

    describe "with text" do
      before do
        within(".js-main-target-form") do
          fill_in "note[note]", with: "This is awesome"
        end
      end

      it 'should have enable submit button and preview button' do
        within(".js-main-target-form") { should_not have_css(".js-comment-button[disabled]") }
        within(".js-main-target-form") { should have_css(".js-note-preview-button", visible: true) }
      end
    end

    describe "with preview" do
      before do
        within(".js-main-target-form") do
          fill_in "note[note]", with: "This is awesome"
          find(".js-note-preview-button").trigger("click")
        end
      end

      it 'should have text and visible edit button' do
        within(".js-main-target-form") { should have_css(".js-note-preview", text: "This is awesome", visible: true) }
        within(".js-main-target-form") { should have_css(".js-note-preview-button", visible: false) }
        within(".js-main-target-form") { should have_css(".js-note-edit-button", visible: true) }
      end
    end
  end

  describe "when posting a note" do
    before do
      within(".js-main-target-form") do
        fill_in "note[note]", with: "This is awsome!"
        find(".js-note-preview-button").trigger("click")
        click_button "Add Comment"
      end
    end

    it 'should be added and form reset' do
      should have_content("This is awsome!")
      within(".js-main-target-form") { should have_no_field("note[note]", with: "This is awesome!")  }
      within(".js-main-target-form") { should have_css(".js-note-preview", visible: false) }
      within(".js-main-target-form") { should have_css(".js-note-text", visible: true) }
    end

    it "should be removable" do
      find(".js-note-delete").trigger("click")
      should_not have_css(".note")
    end
  end
end

describe "On a merge request diff", js: true, focus: true do
  let!(:project) { create(:project_with_code) }
  let!(:merge_request) { create(:merge_request_with_diffs, project: project) }

  before do
    login_as :user
    project.team << [@user, :master]
    visit diffs_project_merge_request_path(project, merge_request)
  end

  subject { page }

  describe "when adding a note" do
    before do
      find("#4735dfc552ad7bf15ca468adc3cad9d05b624490_185_185.line_holder .js-add-diff-note-button").trigger("click")
    end

    describe "the notes holder" do
      it { should have_css("#4735dfc552ad7bf15ca468adc3cad9d05b624490_185_185.line_holder + .js-temp-notes-holder") }

      it { within(".js-temp-notes-holder") { should have_css(".new_note") } }
    end

    describe "the note form" do
      it 'should be valid' do
        within(".js-temp-notes-holder") { find("#note_noteable_type").value.should == "MergeRequest" }
        within(".js-temp-notes-holder") { find("#note_noteable_id").value.should == merge_request.id.to_s }
        within(".js-temp-notes-holder") { find("#note_commit_id").value.should == "" }
        within(".js-temp-notes-holder") { find("#note_line_code").value.should == "4735dfc552ad7bf15ca468adc3cad9d05b624490_185_185" }

        should have_button("Add Comment")
        should have_css(".js-close-discussion-note-form", text: "Cancel")
      end

      it "shouldn't add a second form for same row" do
        find("#4735dfc552ad7bf15ca468adc3cad9d05b624490_185_185.line_holder .js-add-diff-note-button").trigger("click")

        should have_css("#4735dfc552ad7bf15ca468adc3cad9d05b624490_185_185.line_holder + .js-temp-notes-holder form", count: 1)
      end

      it "should be removed when canceled" do
        within(".file form[rel$='4735dfc552ad7bf15ca468adc3cad9d05b624490_185_185']") do
          find(".js-close-discussion-note-form").trigger("click")
        end

        should have_no_css(".js-temp-notes-holder")
      end
    end
  end

  describe "with muliple note forms" do
    before do
      find("#4735dfc552ad7bf15ca468adc3cad9d05b624490_185_185.line_holder .js-add-diff-note-button").trigger("click")
      find("#342e16cbbd482ac2047dc679b2749d248cc1428f_18_17.line_holder .js-add-diff-note-button").trigger("click")
    end

    # has two line forms
    it { should have_css(".js-temp-notes-holder", count: 2) }

    describe "previewing them separately" do
      before do
        # add two separate texts and trigger previews on both
        within("#4735dfc552ad7bf15ca468adc3cad9d05b624490_185_185.line_holder + .js-temp-notes-holder") do
          fill_in "note[note]", with: "One comment on line 185"
          find(".js-note-preview-button").trigger("click")
        end
        within("#342e16cbbd482ac2047dc679b2749d248cc1428f_18_17.line_holder + .js-temp-notes-holder") do
          fill_in "note[note]", with: "Another comment on line 17"
          find(".js-note-preview-button").trigger("click")
        end
      end

      # check if previews were rendered separately
      it { within("#4735dfc552ad7bf15ca468adc3cad9d05b624490_185_185.line_holder + .js-temp-notes-holder") { should have_css(".js-note-preview", text: "One comment on line 185") } }
      it { within("#342e16cbbd482ac2047dc679b2749d248cc1428f_18_17.line_holder + .js-temp-notes-holder") { should have_css(".js-note-preview", text: "Another comment on line 17") } }
    end

    describe "posting a note" do
      before do
        within("#342e16cbbd482ac2047dc679b2749d248cc1428f_18_17.line_holder + .js-temp-notes-holder") do
          fill_in "note[note]", with: "Another comment on line 17"
          click_button("Add Comment")
        end
      end

      # removed form after submit
      it { should have_no_css("#342e16cbbd482ac2047dc679b2749d248cc1428f_18_17.line_holder + .js-temp-notes-holder") }

      it 'should be added as discussion' do
        should have_content("Another comment on line 17")
        should have_css("#342e16cbbd482ac2047dc679b2749d248cc1428f_18_17.line_holder + .notes_holder")
        should have_css("#342e16cbbd482ac2047dc679b2749d248cc1428f_18_17.line_holder + .notes_holder .note", count: 1)
        should have_link("Reply")
      end

      it "should remove last note of a discussion" do
        within("#342e16cbbd482ac2047dc679b2749d248cc1428f_18_17.line_holder + .notes_holder") do
          find(".js-note-delete").trigger("click")
        end

        # removed whole discussion
        should_not have_css(".note_holder")
        should have_css("#342e16cbbd482ac2047dc679b2749d248cc1428f_18_17.line_holder + #342e16cbbd482ac2047dc679b2749d248cc1428f_18_18.line_holder")
      end
    end
  end

  describe "when replying to a note" do
    before do
      # create first note
      find("#4735dfc552ad7bf15ca468adc3cad9d05b624490_184_184.line_holder .js-add-diff-note-button").trigger("click")
      within("#4735dfc552ad7bf15ca468adc3cad9d05b624490_184_184.line_holder + .js-temp-notes-holder") do
        fill_in "note[note]", with: "One comment on line 184"
        click_button("Add Comment")
      end
      # create second note
      within("#4735dfc552ad7bf15ca468adc3cad9d05b624490_184_184.line_holder + .notes_holder") do
        find(".js-discussion-reply-button").trigger("click")
        fill_in "note[note]", with: "An additional comment in reply"
        click_button("Add Comment")
      end
    end

    it 'should be inserted and form removed from reply' do
      should have_content("An additional comment in reply")
      within("#4735dfc552ad7bf15ca468adc3cad9d05b624490_184_184.line_holder + .notes_holder") { should have_css(".note", count: 2) }
      within("#4735dfc552ad7bf15ca468adc3cad9d05b624490_184_184.line_holder + .notes_holder") { should have_no_css("form") }
      within("#4735dfc552ad7bf15ca468adc3cad9d05b624490_184_184.line_holder + .notes_holder") { should have_link("Reply") }
    end
  end
end



describe "On merge request discussion", js: true do
  describe "with merge request diff note"
  describe "with commit note"
  describe "with commit diff note"
end
