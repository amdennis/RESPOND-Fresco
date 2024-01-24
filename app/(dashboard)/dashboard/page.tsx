import ResetButton from './_components/ResetButton';
import AnalyticsButton from './_components/AnalyticsButton';
import RecruitmentTestSection from './_components/RecruitmentTestSection';

function Home() {
  return (
    <>
      <main className="mx-auto flex w-[80%] max-w-[1200px] flex-col gap-10 p-10">
        <h1 className="mb-2 text-3xl font-bold">Welcome</h1>
        <p>This is the main dashboard.</p>
        <ResetButton />
        <RecruitmentTestSection />
        <AnalyticsButton />
      </main>
    </>
  );
}

export default Home;
