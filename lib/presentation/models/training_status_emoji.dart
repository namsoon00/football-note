String trainingStatusEmojiFor(String status) {
  switch (status) {
    case 'great':
      return '🌟';
    case 'good':
      return '🙂';
    case 'tough':
      return '💪';
    case 'recovery':
      return '🧘';
    case 'normal':
    default:
      return '😐';
  }
}
