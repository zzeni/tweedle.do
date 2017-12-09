class TweetsController < ApplicationController
  before_action :set_user, only: [:edit, :create, :update, :destroy]
  before_action :set_tweet, only: [:show, :edit, :update, :destroy]

  # GET /tweets
  def index
    @tweets = Tweet.order(created_at: 'desc').eager_load(:user).page(params[:page]).per(3)
  end

  # GET /tweets/1
  def show
  end

  # GET /tweets/new
  def new
    @tweet = Tweet.new
  end

  # GET /tweets/1/edit
  def edit
  end

  # POST /tweets
  def create
    @tweet = Tweet.new(tweet_params)
    @tweet.user_id = @user.id

    if @tweet.save
      redirect_to root_path, notice: 'Tweet was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /tweets/1
  def update
    if @tweet.update(tweet_params)
      redirect_to root_path, notice: 'Tweet was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /tweets/1
  def destroy
    @tweet.destroy
    redirect_to tweets_url, notice: 'Tweet was successfully destroyed.'
  end

  private
  def set_tweet
    @tweet = Tweet.find(params[:id])
  end

  def set_user
    @user = current_user
    unless @user && params[:user_id] == @user.id.to_s
      redirect_to root_path, alert: "Invalid action"
    end
  end

  # Only allow a trusted parameter "white list" through.
  def tweet_params
    params.require(:tweet).permit(:body)
  end
end
