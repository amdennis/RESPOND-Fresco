'use client';

import { type ColumnDef } from '@tanstack/react-table';
import type { User } from '@prisma/client';
import { ActionsDropdown } from '~/components/DataTable/ActionsDropdown';
import { Checkbox } from '~/components/ui/checkbox';
import { DataTableColumnHeader } from '~/components/DataTable/ColumnHeader';
import {
  Tooltip,
  TooltipContent,
  TooltipProvider,
  TooltipTrigger,
} from '~/components/ui/tooltip';
import { Settings } from 'lucide-react';

type UserWithoutPassword = Omit<User, 'password'>;

export const ParticipantColumns: ColumnDef<UserWithoutPassword>[] = [
  {
    id: 'select',
    header: ({ table }) => (
      <Checkbox
        checked={table.getIsAllPageRowsSelected()}
        onCheckedChange={(value) => table.toggleAllPageRowsSelected(!!value)}
        aria-label="Select all"
      />
    ),
    cell: ({ row }) => (
      <Checkbox
        checked={row.getIsSelected()}
        onCheckedChange={(value) => row.toggleSelected(!!value)}
        aria-label="Select row"
      />
    ),
    enableSorting: false,
    enableHiding: false,
  },
  {
    accessorKey: 'id',
    header: ({ column }) => {
      return <DataTableColumnHeader column={column} title="Participant ID" />;
    },
  },
  {
    accessorKey: 'name',
    header: ({ column }) => {
      return <DataTableColumnHeader column={column} title="Name" />;
    },
  },
  {
    id: 'actions',
    header: () => (
      <TooltipProvider>
        <Tooltip>
          <TooltipTrigger>
            <Settings />
          </TooltipTrigger>
          <TooltipContent>
            <p>Edit or delete an individual participant.</p>
          </TooltipContent>
        </Tooltip>
      </TooltipProvider>
    ),
    cell: () => {
      return <ActionsDropdown menuItems={['Edit', 'Delete']} />;
    },
  },
];
