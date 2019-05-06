require 'slack-ruby-client'
require 'mechanize'

# FIXME
# 環境変数にもたせましょう
Slack.configure do |conf|
	conf.token = 'xoxb-XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX'
end

# RTM Clientのインスタンス生成
client = Slack::RealTime::Client.new


# slackに接続できたときの処理
client.on :hello do
	puts 'connected!'
	client.message channel: '#general', text: 'connected!'
end

# ユーザからのメッセージを検知したときの処理
client.on :message do |data|
	if data['text'].include?('レイワーくん') || data['text'].include?('<@UJA1HUXEG>')
		client.message channel: data['channel'], 
		# 追加していく！
		text: "僕は現在のAmazonランキング10選を教えることができるよ！\n★をつけてカテゴリを選んでください！\n```★ビジネス・経済 \n★コンピュータ・IT \n★科学・テクノロジー 　\n★エンターテイメント \n★歴史・地理  \n★教育・学参・受験 \n★文学・評論 \n★社会・政治```"
	end

	# FIXME
	# メッセージの中に★があれば、カテゴリとしてみな
	if data['text'].include?('★')
		rankings = get_amazon_ranking(data['text'])

		rankings.each{|title, url|
			client.message channel: data['channel'], text: "#{title} \n#{url}"
		}
	end
end

# Amazon.comの対象カテゴリのランキングをスクレイピングで取得する
def get_amazon_ranking(category)
	agent = Mechanize.new
	agent.user_agent_alias = "Windows Mozilla"
	page = agent.get("#{get_amazon_ranking_url(category)}")

	# XMLを配列にする
	titles = convert_array_from_xml_titles(page.search('.p13n-sc-line-clamp-2'))
	urls   = convert_array_from_xml_urls(page.search('.a-col-left .a-link-normal'))

	rankings = {}
	titles.zip(urls) do |title, url| 
		rankings[title] = url
	end 

	return rankings
end

# 追加していく！
def get_amazon_ranking_url(category)
	if category.include?('ビジネス・経済')
		url = 'https://www.amazon.co.jp/gp/new-releases/books/466282'
	else
		exit
	end

	return url
end

# XMLを配列にする
def convert_array_from_xml_titles(xml_titles)
	titles = []
	xml_titles.each_with_index do |xml_title, i|
		titles <<  "#{i + 1}：#{xml_title.inner_text.gsub(/\r\n|\r|\n|\s|\t/, "")}"
		break 1 if i == 9
	end
	return titles
end

# XMLを配列にする
def convert_array_from_xml_urls(xml_urls)
	urls = []
	xml_urls.each_with_index do |xml_url, i|
		# レビューのURLもClass名が同じなので、取得しない
		# 不要なクエリパラメータなどを削除する
		url = xml_url.get_attribute('href').match(/dp\/[a-zA-Z0-9]+/).to_s

		# レビューを除いた際に、空白が入ってしまうので削除する
		if url != ''
			urls << 'https://www.amazon.co.jp/' + url
		end
		break 1 if i == 9
	end
	return urls
end

# Bot start
client.start!
