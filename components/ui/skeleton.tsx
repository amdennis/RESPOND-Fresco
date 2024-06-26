import { cn } from '~/utils/shadcn';

function Skeleton({
  className,
  ...props
}: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      className={cn('animate-pulse rounded-input bg-platinum', className)}
      {...props}
    />
  );
}

export { Skeleton };
