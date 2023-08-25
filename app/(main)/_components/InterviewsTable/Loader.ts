import { prisma } from '~/utils/db';
import { safeLoader } from '~/lib/safeLoader';
import { z } from 'zod';

const InterviewValidation = z.array(
  z.object({
    id: z.string(),
    startTime: z.date(),
    finishTime: z.date().nullable(),
    exportTime: z.date().nullable(),
    lastUpdated: z.date(),
    userId: z.string(),
    protocolId: z.string(),
    currentStep: z.number(),
    network: z.string(),
  }),
);

async function loadInterviews() {
  const interviews = await prisma.interview.findMany({
    include: {
      user: {
        select: {
          name: true,
        },
      },
      protocol: true,
    },
  });

  return interviews;
}

export const safeLoadInterviews = safeLoader({
  outputValidation: InterviewValidation,
  loader: loadInterviews,
});
