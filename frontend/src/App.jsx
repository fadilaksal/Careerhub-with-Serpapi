import React, { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import {
  Search,
  MapPin,
  Briefcase,
  DollarSign,
  Clock,
  ExternalLink,
  Rocket,
  Zap,
  TrendingUp,
} from "lucide-react";

// API configuration
const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080';

// API call to Go backend
const searchJobs = async (query, location) => {
  const params = new URLSearchParams({
    q: query,
    location: location,
  });

  const response = await fetch(`${API_URL}/api/jobs?${params}`);

  if (!response.ok) {
    // Get error details from response body
    let errorMessage = `HTTP ${response.status}: ${response.statusText}`;
    let detailedMessage = null;

    try {
      const errorData = await response.json();
      // Use the message field if available, otherwise use error field
      errorMessage = errorData.message || errorData.error || errorMessage;
      detailedMessage = errorData.message; // Store detailed message separately
    } catch (e) {
      // If response isn't JSON, use default message
    }

    const error = new Error(errorMessage);
    error.status = response.status;
    error.statusText = response.statusText;
    error.detailedMessage = detailedMessage;
    throw error;
  }

  return response.json();
};

const JobCard = ({ job }) => {
  const getTypeColor = (type) => {
    const colors = {
      "Full-time": "from-blue-500 to-cyan-500",
      Contract: "from-purple-500 to-pink-500",
      "Part-time": "from-orange-500 to-red-500",
      Freelance: "from-green-500 to-emerald-500",
    };
    return colors[type] || "from-indigo-500 to-purple-500";
  };

  return (
    <div className="group relative bg-white rounded-2xl border-2 border-slate-100 hover:border-violet-300 p-6 hover:shadow-2xl transition-all duration-300 overflow-hidden">
      {/* Gradient accent on hover */}
      <div className="absolute inset-0 bg-gradient-to-br from-violet-500/0 to-fuchsia-500/0 group-hover:from-violet-500/5 group-hover:to-fuchsia-500/5 transition-all duration-300"></div>

      <div className="relative z-10">
        <div className="flex justify-between items-start mb-4">
          <div className="flex-1">
            <h3 className="text-xl font-bold text-slate-900 mb-1 group-hover:text-violet-600 transition-colors">
              {job.title}
            </h3>
            <p className="text-sm font-semibold text-slate-600">
              {job.company}
            </p>
          </div>
          <span
            className={`px-4 py-2 bg-gradient-to-r ${getTypeColor(
              job.type
            )} text-white rounded-full text-xs font-bold shadow-lg`}
          >
            {job.type}
          </span>
        </div>

        <div className="grid grid-cols-2 gap-3 mb-4">
          <div className="flex items-center gap-2 text-slate-600">
            <MapPin className="w-4 h-4 text-violet-500 flex-shrink-0" />
            <span className="text-sm font-medium">{job.location}</span>
          </div>

          {job.salary && (
            <div className="flex items-center gap-2 text-slate-600">
              <DollarSign className="w-4 h-4 text-green-500 flex-shrink-0" />
              <span className="text-sm font-medium truncate">{job.salary}</span>
            </div>
          )}
        </div>

        <div className="flex items-center gap-2 mb-4 text-slate-500">
          <Clock className="w-4 h-4 text-amber-500 flex-shrink-0" />
          <span className="text-xs font-medium">{job.posted}</span>
        </div>

        <p className="text-slate-600 mb-5 text-sm line-clamp-2 leading-relaxed">
          {job.description}
        </p>

        <a
          href={job.url}
          target="_blank"
          rel="noopener noreferrer"
          className="inline-flex items-center gap-2 px-5 py-2.5 bg-gradient-to-r from-violet-600 to-fuchsia-600 text-white rounded-xl font-semibold hover:from-violet-700 hover:to-fuchsia-700 transition-all duration-300 shadow-lg hover:shadow-xl group/link"
        >
          View Opportunity
          <ExternalLink className="w-4 h-4 group-hover/link:translate-x-1 transition-transform" />
        </a>
      </div>
    </div>
  );
};

export default function App() {
  const [searchQuery, setSearchQuery] = useState("React Developer");
  const [location, setLocation] = useState("Indonesia");
  const [activeQuery, setActiveQuery] = useState("React Developer");
  const [activeLocation, setActiveLocation] = useState("Indonesia");

  const { data, isLoading, isError, error } = useQuery({
    queryKey: ["jobs", activeQuery, activeLocation],
    queryFn: () => searchJobs(activeQuery, activeLocation),
    staleTime: 5 * 60 * 1000,
  });

  const handleSearch = () => {
    setActiveQuery(searchQuery);
    setActiveLocation(location);
  };

  const handleKeyPress = (e) => {
    if (e.key === "Enter") {
      handleSearch();
    }
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-50 via-white to-slate-100">
      {/* Animated background elements */}
      <div className="fixed inset-0 overflow-hidden pointer-events-none">
        <div className="absolute top-0 right-0 w-96 h-96 bg-gradient-to-br from-violet-200 to-fuchsia-200 rounded-full blur-3xl opacity-20 animate-pulse"></div>
        <div className="absolute bottom-0 left-0 w-96 h-96 bg-gradient-to-tr from-blue-200 to-cyan-200 rounded-full blur-3xl opacity-20 animate-pulse"></div>
      </div>

      {/* Header */}
      <div className="z-20 backdrop-blur-sm bg-white/30 border-b border-white/20 sticky top-0">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
          <div className="flex items-center gap-3 mb-8">
            <div className="p-3 bg-gradient-to-br from-violet-600 to-fuchsia-600 rounded-xl shadow-lg">
              <Rocket className="w-6 h-6 text-white" />
            </div>
            <div>
              <h1 className="text-4xl font-black bg-gradient-to-r from-violet-600 to-fuchsia-600 bg-clip-text text-transparent">
                CareerHub
              </h1>
              <p className="text-sm text-slate-600 font-medium">
                Find Your Next Opportunity
              </p>
            </div>
          </div>

          {/* Search Inputs */}
          <div className="flex gap-3 flex-col sm:flex-row">
            <div className="flex-1 relative group">
              <Search className="absolute left-4 top-1/2 transform -translate-y-1/2 text-violet-400 w-5 h-5 group-focus-within:text-violet-600 transition-colors" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                onKeyPress={handleKeyPress}
                placeholder="Developer, Designer, Product Manager..."
                className="w-full pl-12 pr-4 py-3.5 bg-white border-2 border-slate-200 rounded-xl focus:ring-2 focus:ring-violet-500 focus:border-transparent outline-none transition-all duration-300 font-medium shadow-sm hover:border-slate-300"
              />
            </div>

            <div className="sm:w-64 relative group">
              <MapPin className="absolute left-4 top-1/2 transform -translate-y-1/2 text-violet-400 w-5 h-5 group-focus-within:text-violet-600 transition-colors" />
              <input
                type="text"
                value={location}
                onChange={(e) => setLocation(e.target.value)}
                onKeyPress={handleKeyPress}
                placeholder="City or Remote"
                className="w-full pl-12 pr-4 py-3.5 bg-white border-2 border-slate-200 rounded-xl focus:ring-2 focus:ring-violet-500 focus:border-transparent outline-none transition-all duration-300 font-medium shadow-sm hover:border-slate-300"
              />
            </div>

            <button
              onClick={handleSearch}
              className="px-8 py-3.5 bg-gradient-to-r from-violet-600 to-fuchsia-600 text-white rounded-xl hover:from-violet-700 hover:to-fuchsia-700 transition-all duration-300 font-bold shadow-lg hover:shadow-xl flex items-center justify-center gap-2 whitespace-nowrap"
            >
              <Zap className="w-5 h-5" />
              Search
            </button>
          </div>
        </div>
      </div>

      {/* Main Content */}
      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
        {/* Results Header */}
        {data && !isLoading && (
          <div className="mb-8 p-6 bg-gradient-to-r from-violet-50 to-fuchsia-50 rounded-2xl border-2 border-violet-200">
            <div className="flex items-center gap-2 mb-2">
              <TrendingUp className="w-5 h-5 text-violet-600" />
              <p className="text-slate-700 font-semibold">
                Found{" "}
                <span className="text-violet-600 font-bold">
                  {data.jobs.length}
                </span>{" "}
                opportunities for{" "}
                <span className="text-violet-600 font-bold">
                  "{activeQuery}"
                </span>{" "}
                in{" "}
                <span className="text-violet-600 font-bold">
                  {activeLocation}
                </span>
              </p>
            </div>
          </div>
        )}

        {/* Loading State */}
        {isLoading && (
          <div className="flex justify-center items-center py-20">
            <div className="relative w-16 h-16">
              <div className="absolute inset-0 bg-gradient-to-r from-violet-600 to-fuchsia-600 rounded-full animate-spin"></div>
              <div className="absolute inset-2 bg-white rounded-full"></div>
              <div className="absolute inset-2 bg-gradient-to-r from-violet-600/20 to-fuchsia-600/20 rounded-full animate-pulse"></div>
            </div>
          </div>
        )}

        {/* Error State */}
        {isError && (
          <div className="bg-gradient-to-br from-red-50 to-pink-50 border-2 border-red-300 rounded-2xl p-8 shadow-lg">
            <div className="text-4xl mb-3 text-center">⚠️</div>
            <p className="text-red-800 font-bold text-lg mb-2 text-center">
              Failed Search Jobs
            </p>
            <div className="bg-red-100 rounded-xl p-4 mb-3">
              {/* <p className="text-red-700 font-semibold mb-1">Error Message:</p> */}
              <p className="text-red-600 font-medium">{error.message}</p>
            </div>
            {/* {error.status && (
              <div className="flex gap-4 justify-center text-sm">
                <div className="bg-white px-4 py-2 rounded-lg border border-red-200">
                  <span className="text-red-500 font-semibold">Status: </span>
                  <span className="text-red-700">{error.status}</span>
                </div>
                {error.statusText && (
                  <div className="bg-white px-4 py-2 rounded-lg border border-red-200">
                    <span className="text-red-500 font-semibold">
                      Status Text:{" "}
                    </span>
                    <span className="text-red-700">{error.statusText}</span>
                  </div>
                )}
              </div>
            )} */}
            <p className="text-red-500 text-sm mt-4 text-center">
              Try adjusting your search
            </p>
          </div>
        )}

        {/* Job Listings */}
        {data && !isLoading && (
          <div className="space-y-5">
            {data.jobs.map((job) => (
              <JobCard key={job.id} job={job} />
            ))}
          </div>
        )}

        {/* Empty State */}
        {data && data.jobs.length === 0 && !isLoading && (
          <div className="text-center py-20">
            <div className="text-6xl mb-4">🔍</div>
            <p className="text-slate-600 text-xl font-semibold mb-2">
              No opportunities found
            </p>
            <p className="text-slate-500">Try adjusting your search criteria</p>
          </div>
        )}
      </div>

      {/* Footer Note */}
      <div className="relative z-10 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 pb-12">
        <div className="bg-gradient-to-r from-emerald-50 to-teal-50 border-2 border-emerald-300 rounded-2xl p-6 shadow-lg">
          <div className="flex items-start gap-3">
            <div className="text-2xl">✨</div>
            <div>
              <p className="text-emerald-900 font-bold mb-1">
                Connected to Backend
              </p>
              <p className="text-emerald-800 text-sm font-medium">
                Powered by Go backend at{" "}
                <code className="bg-emerald-100 px-2 py-1 rounded-lg font-mono text-xs">
                  {API_URL}/api/jobs
                </code>
              </p>
              <p className="text-emerald-700 text-xs mt-2">
                Make sure your Go server is running
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
