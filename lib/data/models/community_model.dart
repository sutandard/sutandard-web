class ContentWidget {
  final int id;
  final String widgetType;
  final Map<String, dynamic> data;
  final Map<String, dynamic>? resolvedData;
  final DateTime createdAt;

  const ContentWidget({
    required this.id,
    required this.widgetType,
    required this.data,
    this.resolvedData,
    required this.createdAt,
  });

  factory ContentWidget.fromJson(Map<String, dynamic> json) {
    return ContentWidget(
      id: json['id'] as int,
      widgetType: json['widget_type'] as String,
      data: json['data'] as Map<String, dynamic>? ?? {},
      resolvedData: json['resolved_data'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

class WidgetInput {
  final String widgetType;
  final Map<String, dynamic> data;

  /// UI 표시용 이름 (API 전송에는 포함되지 않음)
  final String? displayName;

  const WidgetInput({
    required this.widgetType,
    required this.data,
    this.displayName,
  });

  Map<String, dynamic> toJson() => {
        'widget_type': widgetType,
        'data': data,
      };
}

class Post {
  final int id;
  final String authorName;
  final String title;
  final String content;
  final int? timetable;
  final bool isAnonymous;
  final int likeCount;
  final int commentCount;
  final bool isLiked;
  final bool isMine;
  final List<ContentWidget> widgets;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Post({
    required this.id,
    required this.authorName,
    required this.title,
    required this.content,
    this.timetable,
    this.isAnonymous = false,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLiked = false,
    this.isMine = false,
    this.widgets = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      authorName: json['author_name'] as String? ?? '',
      title: json['title'] as String,
      content: json['content'] as String,
      timetable: json['timetable'] as int?,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      likeCount: json['like_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      isMine: json['is_mine'] as bool? ?? false,
      widgets: (json['widgets'] as List<dynamic>?)
              ?.map((e) => ContentWidget.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Post copyWith({
    int? likeCount,
    bool? isLiked,
    int? commentCount,
  }) {
    return Post(
      id: id,
      authorName: authorName,
      title: title,
      content: content,
      timetable: timetable,
      isAnonymous: isAnonymous,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
      isMine: isMine,
      widgets: widgets,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class PostDetail extends Post {
  final Map<String, dynamic>? timetableDetail;

  const PostDetail({
    required super.id,
    required super.authorName,
    required super.title,
    required super.content,
    super.timetable,
    super.isAnonymous,
    super.likeCount,
    super.commentCount,
    super.isLiked,
    super.isMine,
    super.widgets,
    required super.createdAt,
    required super.updatedAt,
    this.timetableDetail,
  });

  factory PostDetail.fromJson(Map<String, dynamic> json) {
    return PostDetail(
      id: json['id'] as int,
      authorName: json['author_name'] as String? ?? '',
      title: json['title'] as String,
      content: json['content'] as String,
      timetable: json['timetable'] as int?,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      likeCount: json['like_count'] as int? ?? 0,
      commentCount: json['comment_count'] as int? ?? 0,
      isLiked: json['is_liked'] as bool? ?? false,
      isMine: json['is_mine'] as bool? ?? false,
      widgets: (json['widgets'] as List<dynamic>?)
              ?.map((e) => ContentWidget.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      timetableDetail: json['timetable_detail'] as Map<String, dynamic>?,
    );
  }

  @override
  PostDetail copyWith({
    int? likeCount,
    bool? isLiked,
    int? commentCount,
  }) {
    return PostDetail(
      id: id,
      authorName: authorName,
      title: title,
      content: content,
      timetable: timetable,
      isAnonymous: isAnonymous,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
      isMine: isMine,
      widgets: widgets,
      createdAt: createdAt,
      updatedAt: updatedAt,
      timetableDetail: timetableDetail,
    );
  }
}

class PostCreate {
  final String title;
  final String content;
  final int? timetable;
  final bool isAnonymous;
  final List<WidgetInput> widgets;

  const PostCreate({
    required this.title,
    required this.content,
    this.timetable,
    this.isAnonymous = false,
    this.widgets = const [],
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'content': content,
        if (timetable != null) 'timetable': timetable,
        'is_anonymous': isAnonymous,
        'widgets': widgets.map((w) => w.toJson()).toList(),
      };
}

class PostUpdate {
  final String? title;
  final String? content;
  final bool? isAnonymous;

  const PostUpdate({this.title, this.content, this.isAnonymous});

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (content != null) data['content'] = content;
    if (isAnonymous != null) data['is_anonymous'] = isAnonymous;
    return data;
  }
}

class Comment {
  final int id;
  final int post;
  final String authorName;
  final String content;
  final bool isAnonymous;
  final bool isMine;
  final List<ContentWidget> widgets;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Comment({
    required this.id,
    required this.post,
    required this.authorName,
    required this.content,
    this.isAnonymous = false,
    this.isMine = false,
    this.widgets = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'] as int,
      post: json['post'] as int,
      authorName: json['author_name'] as String? ?? '',
      content: json['content'] as String,
      isAnonymous: json['is_anonymous'] as bool? ?? false,
      isMine: json['is_mine'] as bool? ?? false,
      widgets: (json['widgets'] as List<dynamic>?)
              ?.map((e) => ContentWidget.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class CommentCreate {
  final String content;
  final bool isAnonymous;
  final List<WidgetInput> widgets;

  const CommentCreate({
    required this.content,
    this.isAnonymous = false,
    this.widgets = const [],
  });

  Map<String, dynamic> toJson() => {
        'content': content,
        'is_anonymous': isAnonymous,
        'widgets': widgets.map((w) => w.toJson()).toList(),
      };
}

class LikeToggleResponse {
  final bool liked;
  final int likeCount;

  const LikeToggleResponse({
    required this.liked,
    required this.likeCount,
  });

  factory LikeToggleResponse.fromJson(Map<String, dynamic> json) {
    return LikeToggleResponse(
      liked: json['liked'] as bool,
      likeCount: json['like_count'] as int,
    );
  }
}
