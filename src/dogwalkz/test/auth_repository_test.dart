import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:dogwalkz/repositories/auth_repository.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockPostgrestQueryBuilder extends Mock implements PostgrestQueryBuilder {}

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<PostgrestList> {}

void main() {
  group('AuthRepository', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockGoTrueClient mockAuth;
    late MockPostgrestQueryBuilder mockQueryBuilder;
    late MockPostgrestFilterBuilder mockFilterBuilder;
    late AuthRepository authRepository;

    const testEmail = 'test@example.com';
    const testPassword = 'password123';
    const testName = 'Test User';
    const testPhone = '+1234567890';
    const testUserId = 'test-user-id';

    setUpAll(() async {
      // Ensure Supabase is initialized once
      mockSupabaseClient = MockSupabaseClient();
      mockAuth = MockGoTrueClient();
      mockQueryBuilder = MockPostgrestQueryBuilder();
      mockFilterBuilder = MockPostgrestFilterBuilder();

      // Register fallback values to avoid "Missing stub" issues
      registerFallbackValue(Uri());
      registerFallbackValue(<String, dynamic>{});
      registerFallbackValue('users');
      registerFallbackValue('email');
    });

    setUp(() async {
      // Override Supabase singleton
      await Supabase.initialize(
        url: 'https://dummy.supabase.co',
        anonKey: 'dummy-key',
      );
      Supabase.instance.client = mockSupabaseClient;

      when(() => mockSupabaseClient.auth).thenReturn(mockAuth);
      when(
        () => mockSupabaseClient.from(any()),
      ).thenReturn(mockQueryBuilder as SupabaseQueryBuilder);
      when(() => mockQueryBuilder.select(any())).thenReturn(mockFilterBuilder);
      when(
        () => mockFilterBuilder.eq(any(), any()),
      ).thenReturn(mockFilterBuilder);
      when(() => mockFilterBuilder.maybeSingle()).thenAnswer((_) async => null);

      authRepository = AuthRepository(); // unmodified
    });

    group('signUpWithEmail', () {
      test('should successfully sign up a new user', () async {
        final mockUser = User(
          id: testUserId,
          appMetadata: {},
          userMetadata: {'full_name': testName, 'phone': testPhone},
          aud: 'test',
          createdAt: DateTime.now().toIso8601String(),
        );

        final mockAuthResponse = AuthResponse(user: mockUser, session: null);

        when(
          () => mockFilterBuilder.maybeSingle(),
        ).thenAnswer((_) async => null);

        when(
          () => mockAuth.signUp(
            email: testEmail,
            password: testPassword,
            data: {'full_name': testName, 'phone': testPhone},
          ),
        ).thenAnswer((_) async => mockAuthResponse);

        when(
          () => mockQueryBuilder.upsert(any()),
        ).thenAnswer((_) async => mockQueryBuilder);

        await authRepository.signUpWithEmail(
          email: testEmail,
          password: testPassword,
          name: testName,
          phone: testPhone,
        );
      });

      test('should throw AuthException when email already exists', () async {
        when(
          () => mockFilterBuilder.maybeSingle(),
        ).thenAnswer((_) async => {'email': testEmail});

        expect(
          () => authRepository.signUpWithEmail(
            email: testEmail,
            password: testPassword,
            name: testName,
            phone: testPhone,
          ),
          throwsA(isA<AuthException>()),
        );
      });

      test('should throw AuthException when user creation fails', () async {
        when(
          () => mockFilterBuilder.maybeSingle(),
        ).thenAnswer((_) async => null as Map<String, dynamic>?);

        when(
          () => mockAuth.signUp(
            email: testEmail,
            password: testPassword,
            data: {'full_name': testName, 'phone': testPhone},
          ),
        ).thenAnswer((_) async => AuthResponse(user: null, session: null));

        expect(
          () => authRepository.signUpWithEmail(
            email: testEmail,
            password: testPassword,
            name: testName,
            phone: testPhone,
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('signInWithEmail', () {
      test('should successfully sign in user', () async {
        final mockUser = User(
          id: testUserId,
          appMetadata: {},
          userMetadata: {},
          aud: 'test',
          createdAt: DateTime.now().toIso8601String(),
        );

        final mockAuthResponse = AuthResponse(
          user: mockUser,
          session: Session(
            accessToken: 'access_token',
            refreshToken: 'refresh_token',
            expiresIn: 3600,
            tokenType: 'bearer',
            user: mockUser,
          ),
        );

        when(
          () => mockAuth.signInWithPassword(
            email: testEmail,
            password: testPassword,
          ),
        ).thenAnswer((_) async => mockAuthResponse);

        await authRepository.signInWithEmail(
          email: testEmail,
          password: testPassword,
        );
      });

      test('should throw AuthException on login failure', () async {
        when(
          () => mockAuth.signInWithPassword(
            email: testEmail,
            password: testPassword,
          ),
        ).thenThrow(const AuthException('Invalid credentials'));

        expect(
          () => authRepository.signInWithEmail(
            email: testEmail,
            password: testPassword,
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('signOut', () {
      test('should successfully sign out user', () async {
        when(() => mockAuth.signOut()).thenAnswer((_) async {});
        await authRepository.signOut();
      });

      test('should throw AuthException on sign out failure', () async {
        when(
          () => mockAuth.signOut(),
        ).thenThrow(const AuthException('Sign out failed'));

        expect(() => authRepository.signOut(), throwsA(isA<AuthException>()));
      });
    });

    group('currentUser', () {
      test('should return current user when authenticated', () {
        final mockUser = User(
          id: testUserId,
          appMetadata: {},
          userMetadata: {},
          aud: 'test',
          createdAt: DateTime.now().toIso8601String(),
        );

        when(() => mockAuth.currentUser).thenReturn(mockUser);
        expect(authRepository.currentUser, equals(mockUser));
      });

      test('should return null when not authenticated', () {
        when(() => mockAuth.currentUser).thenReturn(null);
        expect(authRepository.currentUser, isNull);
      });
    });
  });
}
