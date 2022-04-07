class TopicData {
  String topic;
  Map<dynamic, dynamic> msg;

  TopicData(this.topic, this.msg);

  TopicData.fromJson(Map<String, dynamic> json) {
    topic = json['topic'];
    msg = json['msg'];
  }
}
