import { PageHeader } from "../components/common/PageHeader";
import { CrowdFunding } from "../components/crowdfunding";

function list() {
  return (
    <div className="flex flex-col min-h-screen bg-gradient-to-br from-gray-300 to-sky-200">
      <PageHeader />
      <div className="container mx-auto bg-white p-5 rounded mt-3">
        <CrowdFunding />
      </div>
    </div>
  );
}

export default list;
