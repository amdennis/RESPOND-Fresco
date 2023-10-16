'use client';

import { DataTable } from '~/components/DataTable/DataTable';
import { ProtocolColumns } from './Columns';
import { trpc } from '~/app/_trpc/client';
import { DeleteProtocol } from '~/app/(dashboard)/dashboard/_components/ProtocolsTable/DeleteProtocols';
import { useState } from 'react';
import type { ProtocolWithInterviews } from '~/shared/types';
import ImportProtocolModal from '../../protocols/_components/ImportProtocolModal';
export const ProtocolsTable = ({
  initialData,
}: {
  initialData: ProtocolWithInterviews[];
}) => {
  const { mutateAsync: deleteProtocols, isLoading: isDeleting } =
    trpc.protocol.delete.byHash.useMutation();
  const {
    isLoading,
    refetch,
    data: protocols,
  } = trpc.protocol.get.all.useQuery(undefined, {
    initialData,
    refetchOnMount: false,
    onError(error) {
      // eslint-disable-next-line no-console
      console.error(error);
    },
  });

  const [showAlertDialog, setShowAlertDialog] = useState(false);
  const [protocolsToDelete, setProtocolsToDelete] = useState<
    ProtocolWithInterviews[]
  >([]);

  const utils = trpc.useContext();

  const handleDelete = (data: ProtocolWithInterviews[]) => {
    setProtocolsToDelete(data);
    setShowAlertDialog(true);
  };

  const handleConfirm = async () => {
    await deleteProtocols(protocolsToDelete.map((d) => d.hash));
    await refetch();
    setShowAlertDialog(false);
  };

  const handleUploaded = () => {
    void utils.protocol.get.all.refetch();
  };

  return (
    <>
      {isLoading && <div>Loading...</div>}
      <ImportProtocolModal onProtocolUploaded={handleUploaded} />
      <DataTable
        columns={ProtocolColumns(handleDelete)}
        data={protocols}
        filterColumnAccessorKey="name"
        handleDeleteSelected={handleDelete}
      />
      <DeleteProtocol
        open={showAlertDialog}
        onCancel={() => setShowAlertDialog(false)}
        onConfirm={handleConfirm}
        selectedProtocols={protocolsToDelete}
        isDeleting={isDeleting}
      />
    </>
  );
};
