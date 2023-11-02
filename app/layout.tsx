/* eslint-disable no-console */
import '~/styles/globals.scss';
import Providers from '../providers/Providers';
import RedirectWrapper from '~/components/RedirectWrapper';
import { getServerSession } from '~/utils/auth';
import { api } from '~/trpc/server';
import { Toaster } from '~/components/ui/toaster';
import { revalidatePath, revalidateTag } from 'next/cache';
import PlausibleProvider from 'next-plausible';

export const metadata = {
  title: 'Network Canvas Fresco',
  description: 'Fresco.',
};

export const dynamic = 'force-dynamic';

async function RootLayout({ children }: { children: React.ReactNode }) {
  const session = await getServerSession();
  const appSettings = await api.appSettings.get.query();

  // If this is the first run, app settings must be created
  if (!appSettings) {
    await api.appSettings.create.mutate();
    revalidateTag('appSettings.get');
    revalidatePath('/');
  }

  return (
    <html lang="en">
      <head>
        <PlausibleProvider
          // this is the domain of the site you want to track
          // TODO: figure out how to track all instances of fresco
          domain="fresco.networkcanvas.com"
          trackLocalhost={true}
          enabled={true}
          taggedEvents={true}
          manualPageviews={true}
        />
      </head>
      <body>
        <RedirectWrapper
          configured={!!appSettings?.configured}
          expired={!!appSettings?.expired}
          session={session}
        >
          <Providers initialSession={session}>{children}</Providers>
          <Toaster />
        </RedirectWrapper>
      </body>
    </html>
  );
}

export default RootLayout;
