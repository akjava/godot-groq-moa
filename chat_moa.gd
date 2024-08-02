extends Control



var api_key = ""
var http_request
var conversations = []
var last_user_prompt
var main_model = "llama-3.1-70b-versatile"

var groq_model_ids =[
	"gemma-7b-it","gemma2-9b-it","llama-3.1-8b-instant",
	"llama3-70b-8192","llama3-8b-8192","mixtral-8x7b-32768","llama-3.1-70b-versatile",
	"llama3-groq-70b-8192-tool-use-preview","llama3-groq-8b-8192-tool-use-preview",	
]
# for list 
var groq_model_ids_short =[
	"gem-7b","gem2-9b","lla31-8b",
	"lla30-70b","lla30-8b","mixtral","lla31-70b",
	"groq-70b","groq-8b",	
]
const MAX_PRESET = 9
const MAX_TEXT = 6
const IMAGE_MAX = 14

		
class Agent:
	var model = "llama-3.1-8b-instant"
	
	var system_prompt = ""
	var last_response = ""
	
var agents = []
var messages_option_button_dic ={}
func update_main_model():
	var option = find_child("MainModelOptionButton")
	var text = option.get_item_text(option.get_selected_id())
	main_model = text

func _set_up_main_option_button():
	
	var option =find_child("MainModelOptionButton")
	for name in groq_model_ids:
		option.add_item(name)
	option.select(6)
		
func _set_up_max_agent_button():
	var option =find_child("MaxAgentOptionButton")
	for i in range(6):
		option.add_item(str(i+1))
	option.select(6)


func _load_main_prompt(index):
	var file_name = _get_main_prompt_path(index)
	var prompt = FileAccess.get_file_as_string(file_name)
	return prompt
func _get_main_prompt_path(index):
	var base_dir = "res://files/prompts/"
	var file_name = "%smain_prompt%s.txt"%[base_dir,index]
	if FileAccess.file_exists(file_name):
		return file_name
	return null
	
func _set_up_prompt_preset():
	var option1 = find_child("MainPromptOptionButton")
	for i in range(1,MAX_PRESET+1):		
		if _get_main_prompt_path(i) != null:
			if i == 1:
				var prompt = _load_main_prompt(i)
				find_child("FinalPromptTextEdit").text = prompt
			option1.add_item("Preset %s"%i)

func _get_max_agent_count():
	var option =find_child("MaxAgentOptionButton")
	return option.get_selected_id()
		


func on_files_dropped(files):
	for file in files:
		if file.ends_with("json"):
			var text = FileAccess.get_file_as_string(file)
			print(text)
			var json = JSON.parse_string(text)
			api_key = json["groq_api_key"]
			find_child("APIKeyLineEdit").text = api_key
			
	
func _ready():
	get_viewport().files_dropped.connect(on_files_dropped)
	_set_up_prompt_preset()
	var setting_path = "res://.env.json"
	
	if !FileAccess.file_exists(setting_path):
		print("not found %s"%setting_path)
		var tab = find_child("TabContainer")
		tab.current_tab = 2
	else:
		var settings = JSON.parse_string(FileAccess.get_file_as_string(setting_path))
		api_key = settings.groq_api_key
		
	# no submit button
	if OS.get_name() == "Web":
		find_child("APIKeyButton").visible = false
		find_child("WebContainer").visible = true
		find_child("AppContainer").visible = false
		find_child("WebCopyContainer").visible = true
		find_child("WebErrorLabel").visible = true
		
		
	else:
		find_child("WebContainer").visible = false
		find_child("AppContainer").visible = true
		
		find_child("WebLabel").visible = false
		find_child("WebCopyContainer").visible = false
		find_child("WebErrorLabel").visible = false
		
	http_request = HTTPRequest.new()
	add_child(http_request)
	
	_set_up_agent_text()
	_set_up_max_agent_button()
	_set_up_main_option_button()
	update_main_model()


	

	
func _setup_llm_option(option_button,selected_index):
	var max = 9
	for name in groq_model_ids_short:
		var label = name.substr(0,max)
		option_button.add_item(label)
	option_button.select(selected_index)
		

func _set_up_agent_text():
	var agents_text = Array(FileAccess.get_file_as_string("res://files/agents.txt").split("\n"))
	agents_text.shuffle()
	var index = 1
	
	for text in agents_text:
		if text == "":
			continue
		find_child("TextEdit%s"%index).text = text
		
		# set up options
		_setup_llm_option(find_child("OptionButton%s"%index),index-1)
		_setup_agent_image(index)
		index+=1
		if index > MAX_TEXT:
			break
	

func _setup_agent_image(index):
	var rand = randi_range(1,IMAGE_MAX)
	var tex = find_child("TextureRect%s"%index)
	# use image loader or not work on release
	var texture =load("res://images/128_%04d.jpg"%rand)
	tex.set_texture(texture)
	
func _set_up_agent():
	agents.clear()
	var agent_container = find_child("AgentContainer")
	var index = 0
	
	for i in range(_get_max_agent_count()):
		var child = find_child("TextEdit%s"%(i+1))
		if child:
			var text = child.text
			if text == "": # end
				break
			var agent = Agent.new()
			agent.system_prompt = text
			var model_index = find_child("OptionButton%s"%(i+1)).get_selected_id()
			agent.model = groq_model_ids[model_index]
			agents.append(agent)
			
	

func _process(delta):
	pass

func _get_option_selected_text(key):
	var option = find_child(key+"OptionButton")
	var text = option.get_item_text(option.get_selected_id())
	return  text

func _add_messages_option_button(label,select=true):
	var option = find_child("MessagesOptionButton")
	option.add_item(label)
	if select:
		option.select(option.item_count-1)
	
var final_response_text = null

func _on_send_button_pressed():
	_set_up_agent()
	final_index = 1 # reset
	conversations = []
	messages_option_button_dic.clear()
	find_child("MessagesOptionButton").clear()
	
	# disable buttons
	find_child("SendButton").disabled = true
	find_child("SummarizeButton").disabled = true
	find_child("ReFinalButton").disabled = true
	
	var input = find_child("InputEdit").text
	
	#_request_chat(input)
	var cycle = find_child("CycleOptionButton").get_selected_id() 
	
	var chained_system_prompt = ""
	
	for i in range(cycle):
		print("cycle %s"%i)
		var cycle_conversations = []
		#var responses = []
		for agent in agents:
			print("[%s]"%agent.system_prompt)
			
			var system = agent.system_prompt
			if agent.model != "gemma2-9b-it":
				system += "\n\n"+chained_system_prompt
			else:
				print("gemma2-9b-it seems broken.skip insert other result")
				
			var error =  _request_chat(agent.model,input,system)
			if error != OK:
				push_error("requested but error happen code = %s"%error)
				return
			
			# TODO support thread,however we need control rate limit
			var res = await http_request.request_completed
			var response = _get_response_text(res[0],res[1],res[2],res[3])
			
			var max_text = 80
			var label = "Cycle %02d:%s"%[i,agent.system_prompt.substr(0,max_text)]
				
			if response == null:
				# get more error info
				push_error("cycle %s error:%s model = %s"%[i,label,agent.model])
				# usually mixtral-8x7b-32768 make error for lower limit,but use first successed
				if agent.last_response != "":
					response = agent.last_response
			else:
				# keep for error
				agent.last_response = response 
					
			if response != null:
				find_child("TextEditA").text = response
				find_child("TextEditB").text = system
				
				
				_add_messages_option_button(label)
				var dic = {"user":input,"model":response,"system":system}
				messages_option_button_dic[label] = dic
				cycle_conversations.append(dic)
					
		
			
		var response_text = ""
		for j in range(cycle_conversations.size()):
			var index = j+1
			var current_response = cycle_conversations[j]["model"]
			response_text +=  "<Agent%s>\n%s\n</Agent%s>\n\n"%[index,current_response,index]
			conversations.append(cycle_conversations[j])
		
		# without this
		
		final_response_text = response_text
		var reference_system_prompt = find_child("FinalPromptTextEdit").text
		chained_system_prompt = reference_system_prompt.replace("{responses}",final_response_text)
		
	
	#insert attributes,before final this prompt effect result especially small Billion models.
	for i in agents.size():
		var index = i+1
		var text = "<Agent%s>"%index
		var replaced = "<Agent%s character='%s'>"%[index,agents[i].system_prompt]
		final_response_text = final_response_text.replace(text,replaced)
	_request_final()
	
	

var final_index = 1
func _request_final(prompt = null):
	find_child("SummarizeButton").disabled = true
	find_child("ReFinalButton").disabled = true
	
	
	var final_header = find_child("FinalAssistantTextEdit").text+"\n\n"
	var reference_system_prompt = find_child("FinalPromptTextEdit").text
	var final_system_prompt = final_header+reference_system_prompt.replace("{responses}",final_response_text)
	
	print("[Final %s]%final_index")
	var input = find_child("InputEdit").text
	
	if prompt!=null:
		input = prompt
	
	print("input prompt = %s"%input)
		
	var error_main =  _request_chat(main_model,input,final_system_prompt)
	if error_main != OK:
		push_error("requested but error happen code = %s"%error_main)
		return
	
		
	
	var res_main = await http_request.request_completed
	var main_response = _get_response_text(res_main[0],res_main[1],res_main[2],res_main[3])
	if main_response!=null:
		find_child("ResponseEdit").text = main_response
		var label = "Final %02d"%final_index
		_add_messages_option_button(label,false)
		var dic = {"user":input,"model":main_response,"system":final_system_prompt}
		messages_option_button_dic[label] = dic
		final_index += 1
		find_child("SummarizeButton").disabled = false
		find_child("ReFinalButton").disabled = false
	else:
		push_error("Final response faild %s"%input)
	
	find_child("SendButton").disabled = false 
	find_child("SummarizeButton").disabled = false
	find_child("ReFinalButton").disabled = false


func _request_chat(model_name,prompt,system_prompt=""):
	
	var url = "https://api.groq.com/openai/v1/chat/completions"
	print(url)
	var contents_value = []
	
	contents_value.append({
			"role":"system",
			"content":system_prompt
		})
		
	for conversation in conversations:
		if conversation.has("user"):
			contents_value.append({
				"role":"user",
				"content":conversation["user"]
			})
		
		if conversation.has("model"):
			contents_value.append({
				"role":"assistant",
				"content":conversation["model"]
			})
			
	contents_value.append({
				"role":"user",
				"content":prompt
			})
	
	var system_parts = []
	
	var body = JSON.new().stringify({
		"model":model_name,
		"messages":contents_value
		
	})
	last_user_prompt = prompt
	print("### send-content model = %s"%[model_name])
	print(str(body))
	if api_key == "":
		api_key = find_child("APIKeyLineEdit").text
	var authorization = "Authorization: Bearer %s"%api_key
	var error = http_request.request(url, ["Content-Type: application/json",authorization], HTTPClient.METHOD_POST, body)
	return error
	

func _set_label_text(key,text):
	var label = find_child(key)
	if text == "HIGH":
		label.get_label_settings().set_font_color(Color(1,0,0,1))
	else:
		label.get_label_settings().set_font_color(Color(1,1,1,1))
	label.text = text
func _on_request_completed(result, responseCode, headers, body):
	pass
	

	
func _get_response_text(result, responseCode, headers, body):
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	print("#### response")
	print(response)
	
	if response == null:
		print("response is null")
		find_child("FinishedLabel").text = "No Response"
		find_child("FinishedLabel").visible = true
		return
	
	
	
	if response.has("error"):
		find_child("FinishedLabel").text = "ERROR"
		find_child("FinishedLabel").visible = true
		find_child("ResponseEdit").text = str(response.error)
		#maybe blocked
		return
	
	#No Answer
	if !response.has("choices"):
		find_child("FinishedLabel").text = "No Choices"
		find_child("FinishedLabel").visible = true
		find_child("ResponseEdit").text = ""
		#maybe blocked
		return
		
	#I can not talk about
	if response.choices[0].finish_reason != "stop":
		find_child("FinishedLabel").text = response.choices[0].finish_reason
		find_child("FinishedLabel").visible = true
		find_child("ResponseEdit").text = ""
	else:
		find_child("FinishedLabel").text = ""
		find_child("FinishedLabel").visible = false
		var newStr = response.choices[0].message.content
		return newStr

func _on_messages_option_button_item_selected(index):
	var text = find_child("MessagesOptionButton").get_item_text(index)
	var dict = messages_option_button_dic[text]
	var response = dict["model"]
	find_child("TextEditA").text = response
	var system = dict["system"]
	find_child("TextEditB").text = system
	


func _on_main_model_option_button_item_selected(index):
	update_main_model()


func _on_re_final_button_pressed():
	_request_final()


func _on_summarize_button_pressed():
	# TODO export text
	var prompt = find_child("SummarizeButton").text
	prompt+=".Replace agent{number} to character role"
	_request_final(prompt)


func _on_reload_button_pressed():
	_set_up_agent_text()


# todo bind index
func _on_texture_rect_mouse_entered():
	var index  = 1
	var text = find_child("TextEdit%s"%index).text.substr(0,50)
	find_child("AgentLabel").text = "(%s)"%text


func _on_set_helpful_assistant_button_pressed():
	for i in range(MAX_TEXT):
		var index = (i+1)
		find_child("TextEdit%s"%index).text = "you are helpfull assistant"


func _on_max_agent_option_button_item_selected(index):
	for i in range(6):
		var v = i < index
		find_child("AgentContainer%s"%(i+1)).visible = v


func _on_api_key_button_pressed():
	var json = {"groq_api_key":find_child("APIKeyLineEdit").text}
	var file = FileAccess.open("res://.env.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(json))
	


func _on_web_download_button_pressed() -> void:
	var text = find_child("WebDownloadTextEdit").text
	JavaScriptBridge.download_buffer(text.to_utf8_buffer(), ".env.json")


func _on_open_url_button_pressed() -> void:
	var url = find_child("OpenUrlButton").text
	OS.shell_open(url)


func _on_main_prompt_option_button_item_selected(index: int) -> void:
	var prompt = _load_main_prompt(index + 1)
	find_child("FinalPromptTextEdit").text = prompt
	


func _on_web_result_download_button_pressed() -> void:
	var text = find_child("ResponseEdit").text
	JavaScriptBridge.download_buffer(text.to_utf8_buffer(), "response.txt")
