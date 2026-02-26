import { createServerClient } from '@supabase/ssr';
import { cookies } from 'next/headers';
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';

const ADMIN_EMAIL = 'rikashrikash04@gmail.com';

export async function GET(request: NextRequest) {
    const { searchParams, origin } = new URL(request.url);
    const code = searchParams.get('code');

    // If there's no code param something went wrong — send back to login
    if (!code) {
        return NextResponse.redirect(`${origin}/?error=missing_code`);
    }

    const cookieStore = await cookies();

    const supabase = createServerClient(
        process.env.NEXT_PUBLIC_SUPABASE_URL!,
        process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
        {
            cookies: {
                getAll() {
                    return cookieStore.getAll();
                },
                setAll(cookiesToSet) {
                    cookiesToSet.forEach(({ name, value, options }) =>
                        cookieStore.set(name, value, options)
                    );
                },
            },
        }
    );

    const { data, error } = await supabase.auth.exchangeCodeForSession(code);

    if (error || !data.session) {
        console.error('[auth/callback] exchangeCodeForSession error:', error);
        return NextResponse.redirect(`${origin}/?error=auth_callback_failed`);
    }

    const userEmail = data.session.user.email ?? '';
    const destination = userEmail === ADMIN_EMAIL ? '/admin' : '/judge';

    return NextResponse.redirect(`${origin}${destination}`);
}
