require 'spec_helper'

describe Octopi::Comment do
  before do
    api_stub("repos/fcoury/octopi")
    api_stub("repos/fcoury/octopi/comments")
  end

  let(:repo) { Octopi::Repo.find("fcoury/octopi") }
  it "has attributes" do
    comment = repo.comments.first
    comment.updated_at.should == "2009-12-15T09:31:19Z"
    comment.line.should be_nil
    comment.body.should_not == ""
    comment.commit_id.should == "a25074f259704821c3193764705a6ad14bede628"
    comment.created_at.should == "2009-12-15T09:31:19Z"
    comment.position.should be_nil
    comment.user.is_a?(Octopi::User).should be_true
    comment.repo.is_a?(Octopi::Repo).should be_true
    comment.id.should == 38684
    comment.url.should == "https://api.github.com/repos/fcoury/octopi/comments/38684"
  end
  
  context "authenticated" do
    before do
      Octopi.authenticate! :username => "radar", :password => "password"
      authenticated_api_stub("repos/fcoury/octopi")
      authenticated_api_stub("repos/fcoury/octopi/commits")
      authenticated_api_stub("repos/fcoury/octopi/comments")
    end

    it "creates a comment" do
      stub_request(:post, authenticated_base_url + "repos/fcoury/octopi/comments").to_return(fake("repos/fcoury/octopi/comments/create"))
      comment = repo.comments.create(:body => "This is a brand new comment!", :commit_id => "38b679a92a49bb49a72e57d99639e26830b7792b")
      comment.is_a?(Octopi::Comment).should be_true
      WebMock.should have_requested(:post, authenticated_base_url + "repos/fcoury/octopi/comments").with(:body => '{"body":"This is a brand new comment!","commit_id":"38b679a92a49bb49a72e57d99639e26830b7792b"}')
    end
    
    it "attempts to create an invalid comment"
  end

  it "retreives a comment"
  it "updates a comment"
  it "deletes a comment"
end