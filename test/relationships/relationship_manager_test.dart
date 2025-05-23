import 'package:flutter_test/flutter_test.dart';
import 'package:quanta_db/relationships/relationship_manager.dart';
import 'package:quanta_db/storage/storage_manager.dart';

void main() {
  late StorageManager storage;
  late RelationshipManager relationshipManager;

  setUp(() {
    storage = StorageManager();
    relationshipManager = RelationshipManager(storage);
  });

  group('RelationshipManager', () {
    test('should initialize relationships correctly', () async {
      final schema = {
        'relationships': [
          {
            'name': 'posts',
            'type': 'hasMany',
            'targetEntity': 'Post',
            'foreignKey': 'authorId',
            'cascade': true,
          },
          {
            'name': 'followers',
            'type': 'manyToMany',
            'targetEntity': 'User',
            'joinTable': 'user_followers',
            'cascade': false,
          },
        ],
      };

      await relationshipManager.initializeRelationships('User', schema);

      // Verify one-to-many relationship
      final postsRel = relationshipManager.relationships['User']!['posts']!;
      expect(postsRel.name, equals('posts'));
      expect(postsRel.type, equals('hasMany'));
      expect(postsRel.targetEntity, equals('Post'));
      expect(postsRel.foreignKey, equals('authorId'));
      expect(postsRel.cascade, isTrue);

      // Verify many-to-many relationship
      final followersRel =
          relationshipManager.relationships['User']!['followers']!;
      expect(followersRel.name, equals('followers'));
      expect(followersRel.type, equals('manyToMany'));
      expect(followersRel.targetEntity, equals('User'));
      expect(followersRel.joinTable, equals('user_followers'));
      expect(followersRel.cascade, isFalse);
    });

    test('should add and get one-to-many relationships', () async {
      final schema = {
        'relationships': [
          {
            'name': 'posts',
            'type': 'hasMany',
            'targetEntity': 'Post',
            'foreignKey': 'authorId',
            'cascade': true,
          },
        ],
      };

      await relationshipManager.initializeRelationships('User', schema);

      // Add relationships
      await relationshipManager.addOneToMany('User', 'posts', 'user1', 'post1');
      await relationshipManager.addOneToMany('User', 'posts', 'user1', 'post2');

      // Get related posts
      final postIds =
          await relationshipManager.getRelatedIds('User', 'posts', 'user1');
      expect(postIds, containsAll(['post1', 'post2']));
    });

    test('should add and get many-to-many relationships', () async {
      final schema = {
        'relationships': [
          {
            'name': 'followers',
            'type': 'manyToMany',
            'targetEntity': 'User',
            'joinTable': 'user_followers',
            'cascade': false,
          },
        ],
      };

      await relationshipManager.initializeRelationships('User', schema);

      // Add relationships
      await relationshipManager.addManyToMany(
          'User', 'followers', 'user1', 'follower1');
      await relationshipManager.addManyToMany(
          'User', 'followers', 'user1', 'follower2');

      // Get followers
      final followerIds =
          await relationshipManager.getRelatedIds('User', 'followers', 'user1');
      expect(followerIds, containsAll(['follower1', 'follower2']));
    });

    test('should remove relationships', () async {
      final schema = {
        'relationships': [
          {
            'name': 'posts',
            'type': 'hasMany',
            'targetEntity': 'Post',
            'foreignKey': 'authorId',
            'cascade': true,
          },
        ],
      };

      await relationshipManager.initializeRelationships('User', schema);

      // Add relationship
      await relationshipManager.addOneToMany('User', 'posts', 'user1', 'post1');

      // Verify relationship exists
      var postIds =
          await relationshipManager.getRelatedIds('User', 'posts', 'user1');
      expect(postIds, contains('post1'));

      // Remove relationship
      await relationshipManager.removeRelationship(
          'User', 'posts', 'user1', 'post1');

      // Verify relationship is removed
      postIds =
          await relationshipManager.getRelatedIds('User', 'posts', 'user1');
      expect(postIds, isEmpty);
    });

    test('should handle cascade delete', () async {
      final schema = {
        'relationships': [
          {
            'name': 'posts',
            'type': 'hasMany',
            'targetEntity': 'Post',
            'foreignKey': 'authorId',
            'cascade': true,
          },
        ],
      };

      await relationshipManager.initializeRelationships('User', schema);

      // Add relationships
      await relationshipManager.addOneToMany('User', 'posts', 'user1', 'post1');
      await relationshipManager.addOneToMany('User', 'posts', 'user1', 'post2');

      // Handle cascade delete
      await relationshipManager.handleCascadeDelete('User', 'posts', 'user1');

      // Verify relationships are removed
      final postIds =
          await relationshipManager.getRelatedIds('User', 'posts', 'user1');
      expect(postIds, isEmpty);
    });
  });
}
