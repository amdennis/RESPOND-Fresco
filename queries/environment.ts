import { createCachedFunction } from '~/lib/cache';
import { prisma } from '~/utils/db';

export const getUploadthingVariables = createCachedFunction(async () => {
  const keyValues = await prisma.environment.findMany({
    where: {
      key: {
        in: ['UPLOADTHING_SECRET', 'UPLOADTHING_APP_ID'],
      },
    },
  });

  const uploadthingVariables = keyValues.reduce(
    (acc, { key, value }) => {
      acc[key] = value;
      return acc;
    },
    {} as Record<string, string>,
  );

  return {
    UPLOADTHING_SECRET: uploadthingVariables.UPLOADTHING_SECRET ?? null,
    UPLOADTHING_APP_ID: uploadthingVariables.UPLOADTHING_APP_ID ?? null,
  };
}, []);
