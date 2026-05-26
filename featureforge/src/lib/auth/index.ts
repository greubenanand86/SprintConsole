import { AuthOptions } from 'next-auth'
import GoogleProvider from 'next-auth/providers/google'
import CredentialsProvider from 'next-auth/providers/credentials'

export const authOptions: AuthOptions = {
  providers: [
    GoogleProvider({
      clientId: process.env.GOOGLE_CLIENT_ID ?? 'not-configured',
      clientSecret: process.env.GOOGLE_CLIENT_SECRET ?? 'not-configured',
    }),
    CredentialsProvider({
      id: 'demo',
      name: 'Demo',
      credentials: {},
      async authorize() {
        return {
          id: 'demo-user-001',
          name: 'Demo User',
          email: 'demo@featureforge.app',
          image: null,
          isDemo: true,
        }
      },
    }),
  ],
  session: { strategy: 'jwt' },
  callbacks: {
    async jwt({ token, account, user }) {
      if (account) {
        token.provider = account.provider
      }
      if (user && (user as { isDemo?: boolean }).isDemo) {
        token.isDemo = true
      }
      return token
    },
    async session({ session, token }) {
      if (session.user) {
        (session.user as { id?: string; isDemo?: boolean }).id = token.sub
        if (token.isDemo) {
          (session.user as { isDemo?: boolean }).isDemo = true
        }
      }
      return session
    },
  },
  pages: {
    signIn: '/',
  },
  secret: process.env.NEXTAUTH_SECRET ?? 'featureforge-dev-secret-do-not-use-in-production',
}
