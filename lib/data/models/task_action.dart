enum TaskActionKind {
  accept('accept'),
  complete('complete'),
  reject('reject', requiresReason: true, isDestructive: true),
  approveCompletion('approve-completion'),
  rework('rework', requiresReason: true);

  const TaskActionKind(
    this.pathSegment, {
    this.requiresReason = false,
    this.isDestructive = false,
  });

  final String pathSegment;
  final bool requiresReason;
  final bool isDestructive;

  String get analyticsName => pathSegment;

  String get translationKey => 'tasks.actions.$name';
}
