// src/pages/Dashboard.js
import React, { useEffect, useState } from 'react';
import { auth, db } from '../firebase/config';
import { doc, getDoc, collection, getDocs, addDoc, deleteDoc, updateDoc } from 'firebase/firestore';
import { signOut } from 'firebase/auth';
import { useNavigate, Link } from 'react-router-dom';
import {
  FaChartBar,
  FaCalendarAlt,
  FaTrashAlt,
  FaTruck,
  FaUsers,
  FaBell,
  FaCogs,
  FaUserCircle,
  FaSignOutAlt,
  FaRecycle,
  FaExclamationCircle,
  FaShareAlt,
  FaClipboardList,
  FaBars,
  FaTimes,
  FaLeaf,
  FaSeedling,
  FaTree,
  FaWater,
  FaSun,
  FaChevronDown,
  FaChevronRight,
  FaEnvelope,
  FaBriefcase,
  FaPhone,
  FaEdit,
  FaInfoCircle, // Import FaInfoCircle for the additional info section
} from 'react-icons/fa';
import Calendar from 'react-calendar'; // Import react-calendar
import 'react-calendar/dist/Calendar.css'; // Import calendar styles
import { format, isSameDay } from 'date-fns';

export default function Dashboard() {
  const [userData, setUserData] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [expandedCategory, setExpandedCategory] = useState(0);
  const [selectedView, setSelectedView] = useState('overview');
  const [residents, setResidents] = useState([]);
  const [residentsLoading, setResidentsLoading] = useState(false);
  const [showModal, setShowModal] = useState(false); // State to control modal visibility
  const [searchQuery, setSearchQuery] = useState(''); // State for search input
  const [selectedRoad, setSelectedRoad] = useState(''); // State for road filter
  const [sharedItems, setSharedItems] = useState([]); // State for shared items
  const [sharedItemsLoading, setSharedItemsLoading] = useState(false); // Loading state for shared items
  const [awarenessData, setAwarenessData] = useState({
    healthIssues: [],
    ongoingCampaigns: [],
    healthAlerts: [],
    publicAwareness: [],
    childrenZone: [],
    contactInfo: [],
    socialMedia: [],
  }); // State for Awareness Zone data
  const [awarenessLoading, setAwarenessLoading] = useState(false); // Loading state for Awareness Zone
  const [selectedSection, setSelectedSection] = useState(null); // State for the selected section
  const [newDetail, setNewDetail] = useState({}); // State for new detail input
  const [selectedItem, setSelectedItem] = useState(null); // State for the selected item
  const [recyclingInfo, setRecyclingInfo] = useState({
    categories: [],
    wasteSegregation: [],
    motivations: { tips: [] },
    recyclingCenters: [],
  });
  const [schedules, setSchedules] = useState([]); // State to store schedules
  const [selectedDate, setSelectedDate] = useState(new Date()); // State for selected date
  const [newSchedule, setNewSchedule] = useState({ wasteType: '' }); // State for new schedule
  const timeSlots = ['8 AM - 10 AM', '10 AM - 12 PM', '12 PM - 2 PM', '2 PM - 4 PM']; // Time slot options
  const navigate = useNavigate();

  const [roads, setRoads] = useState([]); // State to store road list
  const [roadTimeSlots, setRoadTimeSlots] = useState({}); // State to store time slots for each road
  const [selectedRoadForSchedule, setSelectedRoadForSchedule] = useState(''); // State for selected road in schedule form

  const [newRoad, setNewRoad] = useState(''); // State for adding a new road

  const [showPopup, setShowPopup] = useState(false); // State to control popup visibility
  const [popupDate, setPopupDate] = useState(null); // State to store the selected date for the popup

  const [immediatePickups, setImmediatePickups] = useState([]); // State for immediate pickups
  const [selectedPickup, setSelectedPickup] = useState(null); // State for selected pickup

  const [showAssignDriver, setShowAssignDriver] = useState(false); // State to control the Assign Driver dialog
  const [selectedPickupForDriver, setSelectedPickupForDriver] = useState(null); // State for the selected pickup for driver assignment
  const [drivers, setDrivers] = useState([]); // State to store available drivers
  const [selectedDriver, setSelectedDriver] = useState(''); // State for the selected driver

  const [showConfirmPopup, setShowConfirmPopup] = useState(false); // State to control confirmation popup visibility
  const [pickupToConfirm, setPickupToConfirm] = useState(null); // State to store the pickup being confirmed

  const [showEditStatusPopup, setShowEditStatusPopup] = useState(false); // State to control the Edit Status popup
  const [pickupToEditStatus, setPickupToEditStatus] = useState(null); // State for the pickup being edited

  const [totalUsers, setTotalUsers] = useState(0); // State for total users
  const [activeBins, setActiveBins] = useState(0); // State for total active bins
  const [immediatePickupRequests, setImmediatePickupRequests] = useState(0); // State for immediate pickup requests

  const [homeNumbers, setHomeNumbers] = useState([]); // State for home numbers
  const [selectedHomeNumber, setSelectedHomeNumber] = useState(null); // State for selected home number
  const [bins, setBins] = useState([]); // State for bins related to the selected home number
  const [binRequests, setBinRequests] = useState([]); // State for bin requests
  const [homeNumberSearch, setHomeNumberSearch] = useState(''); // Move this state to the top level

  const [reportedIssues, setReportedIssues] = useState([]); // State for reported issues
  const [showIssueDialog, setShowIssueDialog] = useState(false); // State to control issue dialog visibility
  const [selectedIssue, setSelectedIssue] = useState(null); // State for the selected issue
  const [issueReply, setIssueReply] = useState(''); // State for issue reply
  const [issueAction, setIssueAction] = useState(''); // State for issue action

  const [editUserData, setEditUserData] = useState(null); // State for editing user data
  const [isEditing, setIsEditing] = useState(false); // State to control edit mode

  useEffect(() => {
    // Extract unique roads from residents' addresses
    const uniqueRoads = [
      ...new Set(residents.map((resident) => resident.address?.split(',')[0]?.trim()).filter(Boolean)),
    ];
    setRoads(uniqueRoads);
  }, [residents]);

  useEffect(() => {
    const fetchRoads = async () => {
      try {
        const roadsSnapshot = await getDocs(collection(db, 'roads')); // Fetch roads from 'roads' collection
        const roadsData = roadsSnapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }));
        setRoads(roadsData.map((road) => road.name)); // Extract road names
        setRoadTimeSlots(
          roadsData.reduce((acc, road) => {
            acc[road.name] = road.timeSlot || '';
            return acc;
          }, {})
        );
      } catch (err) {
        console.error('Error fetching roads:', err);
      }
    };

    fetchRoads();
  }, []);

  const handleAssignTimeSlot = async (road, timeSlot) => {
    setRoadTimeSlots((prev) => ({
      ...prev,
      [road]: timeSlot,
    }));

    try {
      const roadDoc = (await getDocs(collection(db, 'roads'))).docs.find(
        (doc) => doc.data().name === road
      );
      if (roadDoc) {
        await updateDoc(doc(db, 'roads', roadDoc.id), { timeSlot }); // Update time slot in Firestore
      }
    } catch (err) {
      console.error('Error updating time slot:', err);
    }
  };

  const handleAddRoad = async () => {
    if (newRoad.trim() && !roads.includes(newRoad.trim())) {
      try {
        const roadData = { name: newRoad.trim(), timeSlot: '' };
        const docRef = await addDoc(collection(db, 'roads'), roadData); // Add road to Firestore
        setRoads((prev) => [...prev, roadData.name]);
        setRoadTimeSlots((prev) => ({ ...prev, [roadData.name]: '' }));
        setNewRoad('');
      } catch (err) {
        console.error('Error adding road:', err);
      }
    }
  };

  const handleDeleteRoad = async (road) => {
    try {
      const roadDoc = (await getDocs(collection(db, 'roads'))).docs.find(
        (doc) => doc.data().name === road
      );
      if (roadDoc) {
        await deleteDoc(doc(db, 'roads', roadDoc.id)); // Delete road from Firestore
      }
      setRoads((prev) => prev.filter((r) => r !== road));
      setRoadTimeSlots((prev) => {
        const updated = { ...prev };
        delete updated[road];
        return updated;
      });
    } catch (err) {
      console.error('Error deleting road:', err);
    }
  };

  useEffect(() => {
    const fetchUserData = async () => {
      const user = auth.currentUser;
      if (!user) {
        navigate('/login');
        return;
      }

      try {
        setIsLoading(true);
        const userDoc = await getDoc(doc(db, 'users', user.uid));
        if (userDoc.exists()) {
          setUserData(userDoc.data());
        } else {
          console.error('No user data found');
        }
      } catch (err) {
        console.error('Error fetching user data:', err);
      } finally {
        setIsLoading(false);
      }
    };

    fetchUserData();
  }, [navigate]);

  const fetchResidents = async () => {
    try {
      setResidentsLoading(true);
      const querySnapshot = await getDocs(collection(db, 'users')); // Fetch from 'users' collection
      const residentsData = querySnapshot.docs
        .map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }))
        .filter(
          (user) =>
            !user.position || // Include users without a position
            user.position.toLowerCase() === 'residential' // Case-insensitive comparison for 'Residential'
        );
      setResidents(residentsData);
    } catch (err) {
      console.error('Error fetching residents:', err);
    } finally {
      setResidentsLoading(false);
    }
  };

  const fetchSharedItems = async () => {
    try {
      setSharedItemsLoading(true);
      console.log('Fetching shared items...'); // Debug log
      const querySnapshot = await getDocs(collection(db, 'sharedItems')); // Fetch from 'sharedItems' collection

      if (querySnapshot.empty) {
        console.warn('No shared items found in the database.'); // Warn if collection is empty
      }

      const itemsData = querySnapshot.docs.map((doc) => ({
        id: doc.id,
        ...doc.data(),
      }));

      console.log('Fetched shared items:', itemsData); // Debug log
      setSharedItems(itemsData); // Update state with fetched data
    } catch (err) {
      console.error('Error fetching shared items:', err); // Log errors
    } finally {
      setSharedItemsLoading(false);
    }
  };

  const fetchAwarenessData = async () => {
    try {
      setAwarenessLoading(true);
      const querySnapshot = await getDocs(collection(db, 'awarenessZone')); // Fetch from 'awarenessZone' collection
      const data = querySnapshot.docs.reduce(
        (acc, doc) => {
          const section = doc.data();
          acc[section.type]?.push(section);
          return acc;
        },
        {
          healthIssues: [],
          ongoingCampaigns: [],
          healthAlerts: [],
          publicAwareness: [],
          childrenZone: [],
          contactInfo: [],
          socialMedia: [],
        }
      );
      setAwarenessData(data);
    } catch (err) {
      console.error('Error fetching Awareness Zone data:', err);
    } finally {
      setAwarenessLoading(false);
    }
  };

  const fetchRecyclingInfo = async () => {
    try {
      const categoriesSnapshot = await getDocs(collection(db, 'recyclingCategories'));
      const wasteSegregationSnapshot = await getDocs(collection(db, 'wasteSegregation'));
      const motivationsSnapshot = await getDocs(collection(db, 'recyclingMotivations'));
      const centersSnapshot = await getDocs(collection(db, 'recyclingCenters'));

      setRecyclingInfo({
        categories: categoriesSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() })),
        wasteSegregation: wasteSegregationSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() })),
        motivations: {
          tips: motivationsSnapshot.docs.map((doc) => doc.data().tip),
        },
        recyclingCenters: centersSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() })),
      });
    } catch (err) {
      console.error('Error fetching recycling info:', err);
    }
  };

  const fetchSchedules = async () => {
    try {
      const schedulesSnapshot = await getDocs(collection(db, 'wasteSchedules'));
      setSchedules(schedulesSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() })));
    } catch (err) {
      console.error('Error fetching schedules:', err);
    }
  };

  useEffect(() => {
    if (selectedView === 'residents') {
      fetchResidents();
    } else if (selectedView === 'sharedItems') {
      fetchSharedItems();
    } else if (selectedView === 'awarenessZone') {
      fetchAwarenessData();
    } else if (selectedView === 'recyclingInfo') {
      fetchRecyclingInfo();
    } else if (selectedView === 'schedules') {
      fetchSchedules();
    } else if (selectedView === 'immediatePickups') {
      fetchImmediatePickups();
    } else if (selectedView === 'binStatus') {
      fetchHomeNumbers();
    } else if (selectedView === 'reportedIssues') {
      fetchReportedIssues(); // Fetch reported issues when the "Reported Issues" view is selected
    }
  }, [selectedView]);

  const fetchImmediatePickups = async () => {
    try {
      const pickupsSnapshot = await getDocs(collection(db, 'immediate_pickups')); // Fetch immediate pickups
      setImmediatePickups(pickupsSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() })));
    } catch (err) {
      console.error('Error fetching immediate pickups:', err);
    }
  };

  useEffect(() => {
    const fetchImmediatePickups = async () => {
      try {
        const pickupsSnapshot = await getDocs(collection(db, 'immediate_pickups')); // Fetch immediate pickups
        setImmediatePickups(pickupsSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() })));
      } catch (err) {
        console.error('Error fetching immediate pickups:', err);
      }
    };

    if (selectedView === 'immediatePickups') {
      fetchImmediatePickups();
    }
  }, [selectedView]);

  const fetchDrivers = async () => {
    try {
      const driversSnapshot = await getDocs(collection(db, 'drivers')); // Fetch drivers from 'drivers' collection
      setDrivers(driversSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() })));
    } catch (err) {
      console.error('Error fetching drivers:', err);
    }
  };

  const handleAssignDriver = async () => {
    if (!selectedDriver || !selectedPickupForDriver) return;

    try {
      await updateDoc(doc(db, 'immediate_pickups', selectedPickupForDriver.id), {
        driver: selectedDriver,
      }); // Update driver in Firestore

      setImmediatePickups((prev) =>
        prev.map((pickup) =>
          pickup.id === selectedPickupForDriver.id
            ? { ...pickup, driver: selectedDriver }
            : pickup
        )
      );
      setShowAssignDriver(false); // Close the dialog
      setSelectedPickupForDriver(null); // Clear selected pickup
      setSelectedDriver(''); // Clear selected driver
    } catch (err) {
      console.error('Error assigning driver:', err);
    }
  };

  const handleConfirmPickupPopup = async () => {
    if (!pickupToConfirm) return;
  
    const confirm = window.confirm('Do you want to confirm this pickup?'); // Show browser confirmation dialog
    if (!confirm) {
      setShowConfirmPopup(false); // Close the popup if canceled
      return;
    }
  
    try {
      await updateDoc(doc(db, 'immediate_pickups', pickupToConfirm.id), { status: 'Confirmed' }); // Update status in Firestore
      setImmediatePickups((prev) =>
        prev.map((item) =>
          item.id === pickupToConfirm.id ? { ...item, status: 'Confirmed' } : item
        )
      );
      setShowConfirmPopup(false); // Close the popup
      setPickupToConfirm(null); // Clear the selected pickup
    } catch (err) {
      console.error('Error confirming pickup:', err);
    }
  };

  // Removed duplicate declaration of handleEditPickupStatus

  const logout = async () => {
    await signOut(auth);
    navigate('/');
  };

  const toggleSidebar = () => {
    setSidebarOpen(!sidebarOpen);
  };

  const toggleCategory = (index) => {
    setExpandedCategory(expandedCategory === index ? null : index);
  };

  const openModal = () => {
    setShowModal(true); // Open the modal
  };

  const closeModal = () => {
    setShowModal(false); // Close the modal
    setIsEditing(false); // Exit edit mode if active
  };

  const handleSearchChange = (e) => {
    setSearchQuery(e.target.value.toLowerCase());
  };

  const handleRoadChange = (e) => {
    setSelectedRoad(e.target.value);
  };

  const handleAddDetail = async () => {
    if (!selectedSection || !newDetail.description) return;

    try {
      const sectionCollection = collection(db, 'awarenessZone');
      await addDoc(sectionCollection, {
        type: selectedSection,
        ...newDetail,
      });

      // Update the local state
      setAwarenessData((prev) => ({
        ...prev,
        [selectedSection]: [...prev[selectedSection], newDetail],
      }));

      setNewDetail({}); // Clear the input fields
    } catch (err) {
      console.error('Error adding detail:', err);
    }
  };

  const removeItem = async (itemId) => {
    try {
      await deleteDoc(doc(db, 'sharedItems', itemId)); // Remove item from Firestore
      setSharedItems((prevItems) => prevItems.filter((item) => item.id !== itemId)); // Update state
      setSelectedItem(null); // Close the modal
      console.log(`Item with ID ${itemId} removed successfully.`);
    } catch (err) {
      console.error('Error removing item:', err);
    }
  };

  const handleAddRecyclingCategory = async (newCategory) => {
    try {
      const docRef = await addDoc(collection(db, 'recyclingCategories'), newCategory);
      setRecyclingInfo((prev) => ({
        ...prev,
        categories: [...prev.categories, { id: docRef.id, ...newCategory }],
      }));
    } catch (err) {
      console.error('Error adding recycling category:', err);
    }
  };

  const handleAddWasteSegregation = async (newWaste) => {
    try {
      const docRef = await addDoc(collection(db, 'wasteSegregation'), newWaste);
      setRecyclingInfo((prev) => ({
        ...prev,
        wasteSegregation: [...prev.wasteSegregation, { id: docRef.id, ...newWaste }],
      }));
    } catch (err) {
      console.error('Error adding waste segregation detail:', err);
    }
  };

  const handleAddMotivation = async (newTip) => {
    try {
      const docRef = await addDoc(collection(db, 'recyclingMotivations'), { tip: newTip });
      setRecyclingInfo((prev) => ({
        ...prev,
        motivations: {
          ...prev.motivations,
          tips: [...prev.motivations.tips, newTip],
        },
      }));
    } catch (err) {
      console.error('Error adding motivation:', err);
    }
  };

  const handleAddRecyclingCenter = async (newCenter) => {
    try {
      const docRef = await addDoc(collection(db, 'recyclingCenters'), newCenter);
      setRecyclingInfo((prev) => ({
        ...prev,
        recyclingCenters: [...prev.recyclingCenters, { id: docRef.id, ...newCenter }],
      }));
    } catch (err) {
      console.error('Error adding recycling center:', err);
    }
  };

  const handleAddSchedule = async () => {
    if (!newSchedule.wasteType) return; // Removed time validation

    try {
      const scheduleData = {
        date: selectedDate.toISOString().split('T')[0],
        wasteType: newSchedule.wasteType,
      };
      const docRef = await addDoc(collection(db, 'wasteSchedules'), scheduleData);
      setSchedules((prev) => [...prev, { id: docRef.id, ...scheduleData }]);
      setNewSchedule({ wasteType: '' }); // Reset form
    } catch (err) {
      console.error('Error adding schedule:', err);
    }
  };

  const handleEditSchedule = async (scheduleId, updatedWasteType) => {
    try {
      const scheduleDoc = doc(db, 'wasteSchedules', scheduleId);
      await updateDoc(scheduleDoc, { wasteType: updatedWasteType });
      setSchedules((prev) =>
        prev.map((schedule) =>
          schedule.id === scheduleId ? { ...schedule, wasteType: updatedWasteType } : schedule
        )
      );
    } catch (err) {
      console.error('Error editing schedule:', err);
    }
  };

  const handleDeleteSchedule = async (scheduleId) => {
    try {
      await deleteDoc(doc(db, 'wasteSchedules', scheduleId));
      setSchedules((prev) => prev.filter((schedule) => schedule.id !== scheduleId));
    } catch (err) {
      console.error('Error deleting schedule:', err);
    }
  };

  const handleEditScheduleOld = (scheduleId) => {
    const scheduleToEdit = schedules.find((schedule) => schedule.id === scheduleId);
    if (scheduleToEdit) {
      setNewSchedule({
        wasteType: scheduleToEdit.wasteType,
      });
      setSelectedDate(new Date(scheduleToEdit.date));
    }
  };

  const handleConfirmPickupImmediate = async () => {
    if (!selectedPickup) return;

    try {
      await updateDoc(doc(db, 'immediate_pickups', selectedPickup.id), {
        status: 'Confirmed',
      }); // Update status in Firestore

      setImmediatePickups((prev) =>
        prev.map((pickup) =>
          pickup.id === selectedPickup.id ? { ...pickup, status: 'Confirmed' } : pickup
        )
      );
      setSelectedPickup(null); // Clear selected pickup
    } catch (err) {
      console.error('Error confirming pickup:', err);
    }
  };

  const wasteTypes = {
    Plastic: { 
      color: 'bg-blue-200 text-blue-800', 
      darkColor: 'bg-blue-800',
      icon: '♳'
    },
    'Food Waste': { 
      color: 'bg-yellow-200 text-yellow-800', 
      darkColor: 'bg-yellow-800',
      icon: '🍃'
    },
    'Hazardous Waste': { 
      color: 'bg-red-200 text-red-800', 
      darkColor: 'bg-red-800',
      icon: '⚠️'
    },
    'E-Waste': { 
      color: 'bg-purple-200 text-purple-800', 
      darkColor: 'bg-purple-800',
      icon: '💻'
    },
    Paper: { 
      color: 'bg-green-200 text-green-800', 
      darkColor: 'bg-green-800',
      icon: '📄'
    },
    Glass: { 
      color: 'bg-cyan-200 text-cyan-800', 
      darkColor: 'bg-cyan-800',
      icon: '🥛'
    },
    Metal: { 
      color: 'bg-gray-200 text-gray-800', 
      darkColor: 'bg-gray-800',
      icon: '🔧'
    },
    Other: { 
      color: 'bg-gray-200 text-gray-800', 
      darkColor: 'bg-gray-800',
      icon: '♻️'
    },
  };

  const wasteTypeColors = {
    Plastic: 'bg-blue-200 text-blue-800',
    'Food Waste': 'bg-yellow-200 text-yellow-800',
    'Hazardous Waste': 'bg-red-200 text-red-800',
    'E-Waste': 'bg-purple-200 text-purple-800',
    Other: 'bg-gray-200 text-gray-800',
  };

  const getTileClassName = ({ date }) => {
    if (date < new Date().setHours(0, 0, 0, 0)) {
      return 'text-gray-400'; // Gray out past dates
    }
  
    if (isSameDay(date, selectedDate)) {
      return 'bg-green-200 text-green-800 rounded-full'; // Highlight the selected date
    }
  
    const schedule = schedules.find((s) => isSameDay(new Date(s.date), date));
    return schedule ? `${wasteTypes[schedule.wasteType]?.color || ''} rounded-full` : '';
  };
  
  const handleDateClick = (date) => {
    if (date < new Date().setHours(0, 0, 0, 0)) {
      alert('You cannot schedule a pickup for a past date.');
      return;
    }
  
    setSelectedDate(date); // Highlight the clicked date
    const existingSchedule = schedules.find((s) => isSameDay(new Date(s.date), date));
    if (!existingSchedule) {
      setPopupDate(date);
      setShowPopup(true);
    }
  };

  const renderRoadManagement = () => (
    <div className="bg-white rounded-lg shadow-lg p-6 mb-6">
      <h3 className="text-xl font-bold text-green-700 mb-4">Manage Roads and Assign Time Slots</h3>
  
      {/* Add New Road */}
      <div className="flex items-center mb-4">
        <input
          type="text"
          value={newRoad}
          onChange={(e) => setNewRoad(e.target.value)}
          placeholder="Enter new road name"
          className="flex-1 p-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
        />
        <button
          onClick={handleAddRoad}
          className="ml-4 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
        >
          Add Road
        </button>
      </div>
  
      {/* Roads Table */}
      <table className="min-w-full bg-white border border-gray-200 rounded-lg">
        <thead>
          <tr className="bg-green-100 text-left">
            <th className="py-3 px-4 border-b font-semibold text-green-700">Road Name</th>
            <th className="py-3 px-4 border-b font-semibold text-green-700">Assigned Time Slot</th>
            <th className="py-3 px-4 border-b font-semibold text-green-700">Actions</th>
          </tr>
        </thead>
        <tbody>
          {roads.map((road, idx) => (
            <tr key={idx} className="hover:bg-green-50 transition-colors">
              <td className="py-3 px-4 border-b text-gray-700">{road}</td>
              <td className="py-3 px-4 border-b">
                <select
                  value={roadTimeSlots[road] || ''}
                  onChange={(e) => handleAssignTimeSlot(road, e.target.value)}
                  className="p-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
                >
                  <option value="">Select Time Slot</option>
                  {timeSlots.map((slot, idx) => (
                    <option key={idx} value={slot}>
                      {slot}
                    </option>
                  ))}
                </select>
              </td>
              <td className="py-3 px-4 border-b">
                <button
                  onClick={() => handleDeleteRoad(road)}
                  className="px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600"
                >
                  Delete
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
  
  const renderSchedules = () => {
    const filteredSchedules = schedules.filter((schedule) =>
      isSameDay(new Date(schedule.date), selectedDate)
    );
  
    return (
      <div className="bg-white rounded-lg shadow-lg p-6 mt-6">
        <h2 className="text-2xl font-bold text-green-700 mb-6">Waste Collection Schedules</h2>
  
        {/* Manage Roads and Assign Time Slots */}
        {renderRoadManagement()}
  
        {/* Calendar */}
        <div className="mb-6">
          <Calendar
            onClickDay={handleDateClick} // Handle date click
            value={selectedDate}
            tileClassName={getTileClassName} // Apply color only to valid dates
            className="border-0 rounded-lg shadow-lg w-full max-w-3xl mx-auto bg-white p-4"
            next2Label={null}
            prev2Label={null}
          />
        </div>
  
        {/* Selected Date Info */}
        <div className="bg-green-50 p-4 rounded-lg mb-6">
          <h3 className="text-lg font-semibold text-green-600">
            Selected Date: {format(selectedDate, 'MMMM d, yyyy')}
          </h3>
          <p className="text-sm text-gray-500">
            {filteredSchedules.length > 0
              ? `${filteredSchedules.length} scheduled pickup(s)`
              : 'No pickups scheduled'}
          </p>
        </div>
  
        {/* Existing Schedules */}
        <div className="mb-6">
          <h4 className="text-lg font-bold text-gray-800 mb-4">Schedules for this date:</h4>
          {filteredSchedules.length > 0 ? (
            <ul className="space-y-3">
              {filteredSchedules.map((schedule) => (
                <li
                  key={schedule.id}
                  className={`p-4 rounded-lg shadow-sm border border-gray-200 flex items-center justify-between ${wasteTypes[schedule.wasteType]?.color}`}
                >
                  <div>
                    <p className="text-sm font-medium text-gray-800">
                      <strong>Waste Type:</strong> {schedule.wasteType}
                    </p>
                  </div>
                  <div className="flex space-x-2">
                    <button
                      onClick={() =>
                        handleEditSchedule(schedule.id, prompt('Enter new waste type:', schedule.wasteType))
                      }
                      className="px-4 py-2 bg-yellow-500 text-white rounded-lg hover:bg-yellow-600"
                    >
                      Edit
                    </button>
                    <button
                      onClick={() => handleDeleteSchedule(schedule.id)}
                      className="px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600"
                    >
                      Delete
                    </button>
                  </div>
                </li>
              ))}
            </ul>
          ) : (
            <p className="text-gray-600">No schedules for this date.</p>
          )}
        </div>
      </div>
    );
  };
  
  const renderPopup = () => {
    if (!showPopup) return null;
  
    return (
      <div className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50">
        <div className="bg-white rounded-lg shadow-lg p-6 w-96">
          <h3 className="text-lg font-bold text-gray-800 mb-4">Select Waste Type</h3>
          <select
            onChange={(e) => handleSaveSchedule(e.target.value)}
            className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
          >
            <option value="">Select Waste Type</option>
            {Object.keys(wasteTypes).map((type, idx) => (
              <option key={idx} value={type}>
                {type}
              </option>
            ))}
          </select>
          <button
            onClick={() => setShowPopup(false)}
            className="mt-4 w-full py-2 bg-red-500 text-white rounded-lg hover:bg-red-600"
          >
            Cancel
          </button>
        </div>
      </div>
    );
  };

  const handleSaveSchedule = async (wasteType) => {
    if (!wasteType || !popupDate) return; // Ensure wasteType and popupDate are valid
  
    try {
      const scheduleData = {
        date: popupDate.toISOString().split('T')[0],
        wasteType,
      };
      const docRef = await addDoc(collection(db, 'wasteSchedules'), scheduleData); // Save to Firestore
      setSchedules((prev) => [...prev, { id: docRef.id, ...scheduleData }]); // Update state
      setPopupDate(null); // Clear popup date
      setShowPopup(false); // Close popup
    } catch (err) {
      console.error('Error saving schedule:', err);
    }
  };

  const renderImmediatePickups = () => (
    <div className="bg-white rounded-lg shadow-lg p-6 mt-6">
      <h2 className="text-2xl font-bold text-green-700 mb-6">Immediate Pickups</h2>
  
      {/* Immediate Pickups Table */}
      <div className="overflow-x-auto">
        <table className="min-w-full bg-white border border-gray-200 rounded-lg">
          <thead>
            <tr className="bg-green-100 text-left">
              <th className="py-3 px-4 border-b font-semibold text-green-700">Bin</th>
              <th className="py-3 px-4 border-b font-semibold text-green-700">Pickup Time</th>
              <th className="py-3 px-4 border-b font-semibold text-green-700">Status</th>
              <th className="py-3 px-4 border-b font-semibold text-green-700">Actions</th>
            </tr>
          </thead>
          <tbody>
            {immediatePickups.map((pickup) => (
              <tr
                key={pickup.id}
                className="hover:bg-green-50 transition-colors cursor-pointer"
                onClick={() => setSelectedPickup(pickup)} // Set selected pickup on click
              >
                <td className="py-3 px-4 border-b text-gray-700">{pickup.bin}</td>
                <td className="py-3 px-4 border-b text-gray-600">{pickup.pickupTime}</td>
                <td
                  className={`py-3 px-4 border-b text-gray-600 underline cursor-pointer ${
                    pickup.status === 'Pending' ? 'text-yellow-600' : 'text-green-600'
                  }`}
                  onClick={(e) => {
                    e.stopPropagation(); // Prevent triggering row click
                    if (pickup.status === 'Pending') {
                      setPickupToConfirm(pickup); // Set the pickup to confirm
                      setShowConfirmPopup(true); // Show the confirmation popup
                    } else if (pickup.status === 'Confirmed') {
                      setSelectedPickupForDriver(pickup);
                      setShowAssignDriver(true);
                      fetchDrivers(); // Fetch available drivers
                    }
                  }}
                >
                  {pickup.status}
                </td>
                <td className="py-3 px-4 border-b text-gray-600">
                  <button
                    onClick={(e) => {
                      e.stopPropagation(); // Prevent triggering row click
                      setPickupToEditStatus(pickup); // Set the pickup to edit status
                      setShowEditStatusPopup(true); // Show the Edit Status popup
                    }}
                    className="px-3 py-1 bg-yellow-500 text-white rounded-lg hover:bg-yellow-600"
                  >
                    Edit Status
                  </button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
  
      {/* Modal for Assign Driver */}
      {showAssignDriver && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
          {/* Backdrop */}
          <div
            className="fixed inset-0 bg-black bg-opacity-50 backdrop-blur-sm transition-opacity duration-300"
            onClick={() => setShowAssignDriver(false)} // Close modal on backdrop click
          />
          {/* Modal Content */}
          <div className="relative bg-white rounded-2xl shadow-2xl w-full max-w-md p-6">
            <button
              className="absolute top-4 right-4 text-gray-400 hover:text-gray-600"
              onClick={() => setShowAssignDriver(false)} // Close modal on button click
            >
              <svg
                xmlns="http://www.w3.org/2000/svg"
                className="h-6 w-6"
                fill="none"
                viewBox="0 0 24 24"
                stroke="currentColor"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M6 18L18 6M6 6l12 12"
                />
              </svg>
            </button>
            <h3 className="text-xl font-bold text-gray-800 mb-4">Assign Driver</h3>
            <p className="text-gray-600 mb-4">
              Assign a driver for the pickup at <strong>{selectedPickupForDriver?.bin}</strong>.
            </p>
            <select
              value={selectedDriver}
              onChange={(e) => setSelectedDriver(e.target.value)}
              className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500 mb-4"
            >
              <option value="">Select Driver</option>
              {drivers.map((driver) => (
                <option key={driver.id} value={driver.name}>
                  {driver.name}
                </option>
              ))}
            </select>
            <button
              onClick={handleAssignDriver}
              className="w-full py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
            >
              Assign Driver
            </button>
          </div>
        </div>
      )}
    </div>
  );

  const handleConfirmPickup = async (pickup) => {
    const confirm = window.confirm('Do you want to confirm this pickup?');
    if (!confirm) return;
  
    try {
      await updateDoc(doc(db, 'immediate_pickups', pickup.id), { status: 'Confirmed' }); // Update status in Firestore
      setImmediatePickups((prev) =>
        prev.map((item) =>
          item.id === pickup.id ? { ...item, status: 'Confirmed' } : item
        )
      );
    } catch (err) {
      console.error('Error confirming pickup:', err);
    }
  };

  const handleEditPickup = async (pickup) => {
    const newInstruction = prompt('Edit instruction for this pickup:', pickup.instruction || '');
    if (newInstruction === null) return; // Cancel if no input
  
    try {
      await updateDoc(doc(db, 'immediate_pickups', pickup.id), { instruction: newInstruction }); // Update instruction in Firestore
      setImmediatePickups((prev) =>
        prev.map((item) =>
          item.id === pickup.id ? { ...item, instruction: newInstruction } : item
        )
      );
    } catch (err) {
      console.error('Error editing pickup:', err);
    }
  };

  const filteredResidents = residents.filter((resident) => {
    const matchesSearch =
      resident.name?.toLowerCase().includes(searchQuery) ||
      resident.email?.toLowerCase().includes(searchQuery) ||
      resident.homeNumber?.toLowerCase().includes(searchQuery); // Include homeNumber in search
    const matchesRoad =
      !selectedRoad || resident.address?.toLowerCase().includes(selectedRoad.toLowerCase());
    return matchesSearch && matchesRoad;
  });

  const filteredSharedItems = sharedItems.filter((item) => {
    const matchesSearch =
      item.title?.toLowerCase().includes(searchQuery) || // Search by title
      item.owner?.toLowerCase().includes(searchQuery); // Search by owner
    return matchesSearch; // Remove price and expiration date filters
  });

  const navCategories = [
    {
      title: 'Dashboard',
      icon: <FaLeaf />,
      items: [{ icon: <FaChartBar />, label: 'Overview', view: 'overview' }],
    },
    {
      title: 'Collection',
      icon: <FaRecycle />,
      items: [
        {
          icon: <FaCalendarAlt />,
          label: 'Schedules',
          action: () => setSelectedView('schedules'), // Show schedules when clicked
        },
        { icon: <FaTrashAlt />, label: 'Bin Status', view: 'binStatus' },
        { icon: <FaClipboardList />, label: 'Immediate Pickups', view: 'immediatePickups' }, // Removed Pickup Requests
        { icon: <FaClipboardList />, label: 'Bin Requests', view: 'binRequests' }, // Added Bin Requests
      ],
    },
    {
      title: 'Community',
      icon: <FaSeedling />,
      items: [
        { icon: <FaShareAlt />, label: 'Community Sharing Hub', view: 'sharedItems' }, // Updated view
        { icon: <FaBell />, label: 'Awareness Zone', view: 'awarenessZone' }, // Added Awareness Zone
        { icon: <FaRecycle />, label: 'Recycling Info', view: 'recyclingInfo' }, // Added Recycling Info
      ],
    },
    {
      title: 'Issues',
      icon: <FaExclamationCircle />,
      items: [
        { icon: <FaExclamationCircle />, label: 'Reported Issues', view: 'reportedIssues' },
        { icon: <FaBell />, label: 'Notifications' },
      ],
    },
    {
      title: 'Fleet',
      icon: <FaTruck />,
      items: [{ icon: <FaTruck />, label: 'Truck Tracking' }],
    },
    {
      title: 'Users',
      icon: <FaUsers />,
      items: [
        { icon: <FaUsers />, label: 'Residents', view: 'residents' },
        { icon: <FaUsers />, label: 'Drivers' },
      ],
    },
    {
      title: 'Analytics',
      icon: <FaChartBar />,
      items: [
        { icon: <FaChartBar />, label: 'Collection Reports' },
        { icon: <FaChartBar />, label: 'User Activity' },
        { icon: <FaChartBar />, label: 'Recycling Progress' },
      ],
    },
    {
      title: 'Settings',
      icon: <FaCogs />,
      items: [
        { icon: <FaCogs />, label: 'System' },
        { icon: <FaUserCircle />, label: 'Profile' },
        { icon: <FaCogs />, label: 'Security' },
      ],
    },
  ];

  const renderSectionDetails = () => {
    if (!selectedSection) return null;

    const sectionData = awarenessData[selectedSection] || [];
    const sectionTitle = {
      healthIssues: 'Health Issues',
      ongoingCampaigns: 'Ongoing Health Campaigns',
      healthAlerts: 'Health Alerts',
      publicAwareness: 'Public Health Awareness',
      childrenZone: 'Children Zone',
      contactInfo: 'Contact Information',
      socialMedia: 'Social Media & Website',
    };

    return (
      <div>
        <h3 className="text-xl font-bold text-green-600 mb-4">{sectionTitle[selectedSection]}</h3>
        <ul className="space-y-4">
          {sectionData.map((detail, idx) => (
            <li key={idx} className="bg-green-50 p-4 rounded-lg shadow-sm border border-green-100">
              <p className="text-gray-800">{detail.description}</p>
              {detail.location && <p className="text-gray-600">Location: {detail.location}</p>}
              {detail.time && <p className="text-gray-600">Time: {detail.time}</p>}
              {detail.note && <p className="text-gray-600">Note: {detail.note}</p>}
            </li>
          ))}
        </ul>

        {/* Add New Detail */}
        <div className="mt-6">
          <h4 className="text-lg font-semibold text-gray-800 mb-2">Add New Detail</h4>
          <input
            type="text"
            placeholder="Description"
            className="w-full p-2 border border-gray-300 rounded-lg mb-2"
            value={newDetail.description || ''}
            onChange={(e) => setNewDetail({ ...newDetail, description: e.target.value })}
          />
          {selectedSection === 'ongoingCampaigns' && (
            <>
              <input
                type="text"
                placeholder="Location"
                className="w-full p-2 border border-gray-300 rounded-lg"
                value={newDetail.location || ''}
                onChange={(e) => setNewDetail({ ...newDetail, location: e.target.value })}
              />
              <input
                type="text"
                placeholder="Time"
                className="w-full p-2 border border-gray-300 rounded-lg"
                value={newDetail.time || ''}
                onChange={(e) => setNewDetail({ ...newDetail, time: e.target.value })}
              />
            </>
          )}
          {selectedSection === 'healthAlerts' && (
            <input
              type="text"
              placeholder="Note"
              className="w-full p-2 border border-gray-300 rounded-lg"
              value={newDetail.note || ''}
              onChange={(e) => setNewDetail({ ...newDetail, note: e.target.value })}
            />
          )}
          {/* Add other fields for other sections as needed */}
          <button
            onClick={handleAddDetail}
            className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
          >
            Add Detail
          </button>
        </div>
      </div>
    );
  };

  const renderRecyclingInfo = () => {
    return (
      <div className="bg-white rounded-lg shadow-lg p-6 mt-6">
        <h2 className="text-2xl font-bold text-green-700 mb-6">Recycling Information</h2>

        {/* Recycling Categories */}
        <div className="mb-8">
          <h3 className="text-xl font-semibold text-green-600 mb-4">Recycling Categories</h3>
          {recyclingInfo.categories.map((category) => (
            <div key={category.id} className="mb-4">
              <h4 className="text-lg font-bold text-gray-800">{category.name}</h4>
              <p className="text-gray-600">Recyclable Items: {category.items.join(', ')}</p>
              <p className="text-gray-600">Tips: {category.tips}</p>
            </div>
          ))}
          <form
            onSubmit={(e) => {
              e.preventDefault();
              const formData = new FormData(e.target);
              handleAddRecyclingCategory({
                name: formData.get('name'),
                items: formData.get('items').split(',').map((item) => item.trim()),
                tips: formData.get('tips'),
              });
              e.target.reset();
            }}
          >
            <input name="name" placeholder="Category Name" className="w-full p-2 border mb-2" required />
            <input name="items" placeholder="Items (comma-separated)" className="w-full p-2 border mb-2" required />
            <textarea name="tips" placeholder="Tips" className="w-full p-2 border mb-2" required />
            <button type="submit" className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700">
              Add Category
            </button>
          </form>
        </div>

        {/* Waste Segregation Guide */}
        <div className="mb-8">
          <h3 className="text-xl font-semibold text-green-600 mb-4">Waste Segregation Guide</h3>
          {recyclingInfo.wasteSegregation.map((waste) => (
            <div key={waste.id} className="mb-4 p-4 bg-gray-50 rounded-lg shadow-sm border border-gray-200">
              <h4 className="text-lg font-bold text-gray-800">{waste.type}</h4>
              <p className="text-gray-600">How to Dispose: {waste.howToDispose}</p>
              <p className="text-gray-600">Examples: {waste.examples.join(', ')}</p>
              <p className="text-gray-600">Tips: {waste.tips}</p>
            </div>
          ))}
          <form
            onSubmit={(e) => {
              e.preventDefault();
              const formData = new FormData(e.target);
              handleAddWasteSegregation({
                type: formData.get('type'),
                howToDispose: formData.get('howToDispose'),
                examples: formData.get('examples').split(',').map((item) => item.trim()),
                tips: formData.get('tips'),
              });
              e.target.reset();
            }}
            className="space-y-4"
          >
            <h4 className="text-lg font-bold text-gray-800">Add New Waste Type</h4>
            <input
              name="type"
              placeholder="Waste Type"
              className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
              required
            />
            <textarea
              name="howToDispose"
              placeholder="How to Dispose"
              className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
              required
            />
            <input
              name="examples"
              placeholder="Examples (comma-separated)"
              className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
              required
            />
            <textarea
              name="tips"
              placeholder="Tips"
              className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
              required
            />
            <button
              type="submit"
              className="w-full py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-all"
            >
              Add Waste Type
            </button>
          </form>
        </div>

        {/* Motivations to Recycle */}
        <div className="mb-8">
          <h3 className="text-xl font-semibold text-green-600 mb-4">Motivations to Recycle</h3>
          <ul className="list-disc pl-6 space-y-2">
            {recyclingInfo.motivations.tips.map((tip, idx) => (
              <li key={idx} className="text-gray-600">{tip}</li>
            ))}
          </ul>
          <form
            onSubmit={(e) => {
              e.preventDefault();
              const formData = new FormData(e.target);
              handleAddMotivation(formData.get('tip'));
              e.target.reset();
            }}
            className="space-y-4 mt-4"
          >
            <h4 className="text-lg font-bold text-gray-800">Add New Motivation</h4>
            <textarea
              name="tip"
              placeholder="Motivation Tip"
              className="w-full p-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
              required
            />
            <button
              type="submit"
              className="w-full py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-all"
            >
              Add Motivation
            </button>
          </form>
        </div>

        {/* Nearest Recycling Centers */}
        <div>
          <h3 className="text-xl font-semibold text-green-600 mb-4">Nearest Recycling Centers</h3>
          {recyclingInfo.recyclingCenters.map((center) => (
            <div key={center.id} className="mb-4">
              <h4 className="text-lg font-bold text-gray-800">{center.name}</h4>
              <p className="text-gray-600">Address: {center.address}</p>
              <p className="text-gray-600">Open Hours: {center.openHours}</p>
              <p className="text-gray-600">Accepted Materials: {center.acceptedMaterials.join(', ')}</p>
              <a
                href={center.directions}
                target="_blank"
                rel="noopener noreferrer"
                className="text-green-600 hover:underline"
              >
                Get Directions
              </a>
            </div>
          ))}
          <form
            onSubmit={(e) => {
              e.preventDefault();
              const formData = new FormData(e.target);
              handleAddRecyclingCenter({
                name: formData.get('name'),
                address: formData.get('address'),
                openHours: formData.get('openHours'),
                acceptedMaterials: formData.get('acceptedMaterials').split(',').map((item) => item.trim()),
                directions: formData.get('directions'),
              });
              e.target.reset();
            }}
          >
            <input name="name" placeholder="Center Name" className="w-full p-2 border mb-2" required />
            <input name="address" placeholder="Address" className="w-full p-2 border mb-2" required />
            <input name="openHours" placeholder="Open Hours" className="w-full p-2 border mb-2" required />
            <input
              name="acceptedMaterials"
              placeholder="Accepted Materials (comma-separated)"
              className="w-full p-2 border mb-2"
              required
            />
            <input name="directions" placeholder="Google Maps Link" className="w-full p-2 border mb-2" required />
            <button type="submit" className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700">
              Add Recycling Center
            </button>
          </form>
        </div>
      </div>
    );
  };

  const renderOverview = () => (
    <div className="grid grid-cols-1 md:grid-cols-4 gap-6 mt-6">
      {/* Total Users */}
      <div className="bg-white rounded-lg shadow-lg p-6 flex items-center">
        <div className="p-4 bg-green-100 rounded-full text-green-600">
          <FaUsers className="text-3xl" />
        </div>
        <div className="ml-4">
          <h3 className="text-lg font-semibold text-gray-800">Total Users</h3>
          <p className="text-2xl font-bold text-green-600">{totalUsers}</p>
        </div>
      </div>
  
      {/* Total Bins */}
      <div className="bg-white rounded-lg shadow-lg p-6 flex items-center">
        <div className="p-4 bg-blue-100 rounded-full text-blue-600">
          <FaTrashAlt className="text-3xl" />
        </div>
        <div className="ml-4">
          <h3 className="text-lg font-semibold text-gray-800">Total Bins</h3>
          <p className="text-2xl font-bold text-blue-600">{activeBins}</p>
        </div>
      </div>
  
      {/* Requested Bins */}
      <div className="bg-white rounded-lg shadow-lg p-6 flex items-center">
        <div className="p-4 bg-yellow-100 rounded-full text-yellow-600">
          <FaClipboardList className="text-3xl" />
        </div>
        <div className="ml-4">
          <h3 className="text-lg font-semibold text-gray-800">Requested Bins</h3>
          <p className="text-2xl font-bold text-yellow-600">{binRequests.length}</p>
        </div>
      </div>
  
      {/* Reported Issues */}
      <div className="bg-white rounded-lg shadow-lg p-6 flex items-center">
        <div className="p-4 bg-red-100 rounded-full text-red-600">
          <FaExclamationCircle className="text-3xl" />
        </div>
        <div className="ml-4">
          <h3 className="text-lg font-semibold text-gray-800">Reported Issues</h3>
          <p className="text-2xl font-bold text-red-600">{reportedIssues.length}</p>
        </div>
      </div>
    </div>
  );

  const formatBinId = (homeNumber, index) => `BIN-${homeNumber}-${String(index + 1).padStart(3, '0')}`;

  const renderBinStatus = () => {
    const filteredHomeNumbers = homeNumbers.filter((homeNumber) =>
      homeNumber.toLowerCase().includes(homeNumberSearch.toLowerCase())
    );
  
    return (
      <div className="bg-white rounded-lg shadow-lg p-6 mt-6">
        <h2 className="text-2xl font-bold text-green-700 mb-6">Bin Status</h2>
  
        {/* Home Numbers List */}
        <div className="mb-6">
          <h3 className="text-lg font-semibold text-gray-800 mb-4">Select Home Number</h3>
          <input
            type="text"
            placeholder="Search Home Number"
            value={homeNumberSearch}
            onChange={(e) => setHomeNumberSearch(e.target.value)}
            className="w-full p-2 mb-4 border border-gray-300 rounded-lg focus:ring-2 focus:ring-green-500"
          />
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
            {filteredHomeNumbers.map((homeNumber, idx) => (
              <button
                key={idx}
                onClick={() => {
                  setSelectedHomeNumber(homeNumber);
                  fetchBinsForHomeNumber(homeNumber);
                }}
                className={`px-4 py-2 rounded-lg font-medium ${
                  selectedHomeNumber === homeNumber
                    ? 'bg-green-600 text-white'
                    : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                }`}
              >
                {homeNumber}
              </button>
            ))}
          </div>
        </div>
  
        {/* Bins Table */}
        {selectedHomeNumber && (
          <div className="mb-6">
            <h3 className="text-lg font-semibold text-gray-800 mb-4">
              Bins for Home Number: {selectedHomeNumber}
            </h3>
            <table className="min-w-full bg-white border border-gray-200 rounded-lg">
              <thead>
                <tr className="bg-green-100 text-left">
                  <th className="py-3 px-4 border-b font-semibold text-green-700">Bin ID</th>
                  <th className="py-3 px-4 border-b font-semibold text-green-700">Status</th>
                  <th className="py-3 px-4 border-b font-semibold text-green-700">Actions</th>
                </tr>
              </thead>
              <tbody>
                {bins.map((bin, index) => (
                  <tr key={bin.id} className="hover:bg-green-50 transition-colors">
                    <td className="py-3 px-4 border-b text-gray-700">
                      {formatBinId(selectedHomeNumber, index)}
                    </td>
                    <td className="py-3 px-4 border-b text-gray-600">{bin.status}</td>
                    <td className="py-3 px-4 border-b">
                      {bin.status === 'Inactive' && (
                        <button
                          onClick={() => handleActivateBin(bin.id)}
                          className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
                        >
                          Activate
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    );
  };

  useEffect(() => {
    if (selectedView === 'binRequests') {
      fetchBinRequests(); // Fetch bin requests only when the "Bin Requests" view is selected
    }
  }, [selectedView]);

  const renderBinRequests = () => (
    <div className="bg-white rounded-lg shadow-lg p-6 mt-6">
      <h2 className="text-2xl font-bold text-green-700 mb-6">Bin Requests</h2>
      <table className="min-w-full bg-white border border-gray-200 rounded-lg">
        <thead>
          <tr className="bg-green-100 text-left">
            <th className="py-3 px-4 border-b font-semibold text-green-700">Bin ID</th>
            <th className="py-3 px-4 border-b font-semibold text-green-700">Requested Date</th>
            <th className="py-3 px-4 border-b font-semibold text-green-700">Reason</th>
            <th className="py-3 px-4 border-b font-semibold text-green-700">Waste Type</th>
            <th className="py-3 px-4 border-b font-semibold text-green-700">Location</th>
            <th className="py-3 px-4 border-b font-semibold text-green-700">Capacity</th>
            <th className="py-3 px-4 border-b font-semibold text-green-700">Want Immediately</th>
            <th className="py-3 px-4 border-b font-semibold text-green-700">Status</th>
            <th className="py-3 px-4 border-b font-semibold text-green-700">Actions</th>
          </tr>
        </thead>
        <tbody>
          {binRequests.map((request) => (
            <tr key={request.id} className="hover:bg-green-50 transition-colors">
              <td className="py-3 px-4 border-b text-gray-700">{request.id}</td>
              <td className="py-3 px-4 border-b text-gray-600">
                {request.createdAt?.toDate().toLocaleString() || 'Unknown'}
              </td>
              <td className="py-3 px-4 border-b text-gray-600">{request.reason}</td>
              <td className="py-3 px-4 border-b text-gray-600">{request.type}</td>
              <td className="py-3 px-4 border-b text-gray-600">{request.location}</td>
              <td className="py-3 px-4 border-b text-gray-600">{request.capacity} L</td>
              <td className="py-3 px-4 border-b text-gray-600">
                {request.wantImmediately ? 'Yes' : 'No'}
              </td>
              <td className="py-3 px-4 border-b text-gray-600">{request.status}</td>
              <td className="py-3 px-4 border-b">
                <button
                  onClick={() => openEditDialog(request)}
                  className="text-gray-500 hover:text-green-600"
                >
                  <FaEdit />
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );

  const openEditDialog = (request) => {
    setPickupToEditStatus(request); // Set the selected request
    setShowEditStatusPopup(true); // Show the dialog
  };

  const handleEditPickupStatus = async () => {
    if (!pickupToEditStatus) return;

    try {
      await updateDoc(doc(db, 'binRequests', pickupToEditStatus.id), { status: 'Confirmed' }); // Update status in Firestore
      setBinRequests((prev) =>
        prev.map((request) =>
          request.id === pickupToEditStatus.id ? { ...request, status: 'Confirmed' } : request
        )
      );
      setShowEditStatusPopup(false); // Close the dialog
      setPickupToEditStatus(null); // Clear the selected request
    } catch (err) {
      console.error('Error editing bin request status:', err);
    }
  };

  const fetchReportedIssues = async () => {
    try {
      const issuesSnapshot = await getDocs(collection(db, 'reportedIssues')); // Fetch from 'reportedIssues' collection
      setReportedIssues(
        issuesSnapshot.docs.map((doc) => ({
          id: doc.id,
          ...doc.data(),
        }))
      );
    } catch (err) {
      console.error('Error fetching reported issues:', err);
    }
  };

  const handleSaveIssueResponse = async () => {
    if (!selectedIssue || !issueReply || !issueAction) return;

    try {
      await updateDoc(doc(db, 'reportedIssues', selectedIssue.id), {
        reply: issueReply,
        action: issueAction,
      }); // Save reply and action to Firestore

      setReportedIssues((prev) =>
        prev.map((issue) =>
          issue.id === selectedIssue.id
            ? { ...issue, reply: issueReply, action: issueAction }
            : issue
        )
      );
      setShowIssueDialog(false); // Close the dialog
      setSelectedIssue(null); // Clear the selected issue
      setIssueReply(''); // Reset reply
      setIssueAction(''); // Reset action
    } catch (err) {
      console.error('Error saving issue response:', err);
    }
  };

  const handleAddReportedIssue = async (newIssue) => {
    try {
      const issueData = {
        ...newIssue,
        timestamp: new Date(), // Add current timestamp
      };
      const docRef = await addDoc(collection(db, 'reportedIssues'), issueData); // Save to Firestore
      setReportedIssues((prev) => [...prev, { id: docRef.id, ...issueData }]); // Update state
    } catch (err) {
      console.error('Error adding reported issue:', err);
    }
  };

  const renderReportedIssues = () => (
    <div className="bg-white rounded-lg shadow-lg p-6 mt-6">
      <h2 className="text-2xl font-bold text-green-700 mb-6">Reported Issues</h2>
      <table className="min-w-full bg-white border border-gray-200 rounded-lg">
        <thead>
          <tr className="bg-green-100 text-left">
            <th className="py-3 px-4 border-b font-semibold text-green-700">Title</th>
            <th className="py-3 px-4 border-b font-semibold text-green-700">Category</th>
            <th className="py-3 px-4 border-b font-semibold text-green-700">Status</th>
            <th className="py-3 px-4 border-b font-semibold text-green-700">Urgent</th>
          </tr>
        </thead>
        <tbody>
          {/* Data rows will be dynamically loaded here */}
        </tbody>
      </table>
    </div>
  );

  const openIssueDialog = (issue) => {
    setSelectedIssue(issue); // Set the selected issue
    setIssueReply(issue.reply || ''); // Pre-fill reply if available
    setIssueAction(issue.action || ''); // Pre-fill action if available
    setShowIssueDialog(true); // Show the dialog
  };

  const renderContent = () => {
    if (selectedView === 'overview') {
      return (
        <div className="bg-white rounded-lg shadow-lg p-6 mt-6">
          <h2 className="text-2xl font-bold text-green-700 mb-6">Dashboard Overview</h2>
          {renderOverview()}
        </div>
      );
    }
  
    if (selectedView === 'awarenessZone') {
      return (
        <div className="bg-white rounded-lg shadow-lg p-6 mt-6">
          <h2 className="text-2xl font-bold text-green-700 mb-6">Awareness Zone</h2>

          {/* Section Selection */}
          <div className="flex flex-wrap gap-4 mb-6">
            {Object.keys(awarenessData).map((sectionKey) => (
              <button
                key={sectionKey}
                onClick={() => setSelectedSection(sectionKey)} // Set the selected section
                className={`px-4 py-2 rounded-lg font-medium ${
                  selectedSection === sectionKey
                    ? 'bg-green-600 text-white'
                    : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                }`}
              >
                {sectionKey.replace(/([A-Z])/g, ' $1').replace(/^./, (str) => str.toUpperCase())}
              </button>
            ))}
          </div>

          {/* Render Section Details */}
          {renderSectionDetails()}
        </div>
      );
    }

    if (selectedView === 'residents') {
      return (
        <div className="bg-white rounded-lg shadow-lg p-6 mt-6">
          <h2 className="text-2xl font-bold text-green-700 mb-6">Residents Details</h2>

          {/* Search and Filter */}
          <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-6">
            <input
              type="text"
              placeholder="Search by name or email"
              className="w-full md:w-1/3 p-2 border border-gray-300 rounded-lg mb-4 md:mb-0"
              value={searchQuery}
              onChange={handleSearchChange}
            />
            <select
              className="w-full md:w-1/4 p-2 border border-gray-300 rounded-lg"
              value={selectedRoad}
              onChange={handleRoadChange}
            >
              <option value="">All Roads</option>
              {[...new Set(residents.map((resident) => resident.address?.split(',')[0]))]
                .filter(Boolean)
                .map((road, idx) => (
                  <option key={idx} value={road}>
                    {road}
                  </option>
                ))}
            </select>
          </div>

          {residentsLoading ? (
            <div className="flex items-center justify-center py-12">
              <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-green-600"></div>
            </div>
          ) : filteredResidents.length > 0 ? (
            <div className="overflow-x-auto">
              <table className="min-w-full bg-white border border-gray-200 rounded-lg">
                <thead>
                  <tr className="bg-green-100 text-left">
                    <th className="py-3 px-4 border-b font-semibold text-green-700">Home Number</th>
                    <th className="py-3 px-4 border-b font-semibold text-green-700">Name</th>
                    <th className="py-3 px-4 border-b font-semibold text-green-700">Home Number, Address</th>
                    <th className="py-3 px-4 border-b font-semibold text-green-700">Email</th>
                    <th className="py-3 px-4 border-b font-semibold text-green-700">Phone</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredResidents.map((resident) => (
                    <tr key={resident.id} className="hover:bg-green-50 transition-colors">
                      <td className="py-3 px-4 border-b text-gray-700">{resident.homeNumber || 'N/A'}</td>
                      <td className="py-3 px-4 border-b text-gray-700">{resident.name}</td>
                      <td className="py-3 px-4 border-b text-gray-600">
                        {`${resident.homeNumber || 'N/A'}, ${resident.address || 'N/A'}`}
                      </td>
                      <td className="py-3 px-4 border-b text-gray-600">{resident.email}</td>
                      <td className="py-3 px-4 border-b text-gray-600">{resident.phone || 'N/A'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="text-center py-12">
              <p className="text-gray-600">No residents found.</p>
            </div>
          )}
        </div>
      );
    } else if (selectedView === 'sharedItems') {
      console.log('Rendering shared items:', sharedItems); // Debug log

      return (
        <div className="bg-white rounded-lg shadow-lg p-6 mt-6">
          <h2 className="text-2xl font-bold text-green-700 mb-6">Community Sharing Hub</h2>

          {/* Search */}
          <div className="flex flex-col md:flex-row md:items-center md:justify-between mb-6">
            <input
              type="text"
              placeholder="Search by title or owner name"
              className="w-full md:w-1/3 p-2 border border-gray-300 rounded-lg"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value.toLowerCase())} // Update search query
            />
          </div>

          {sharedItemsLoading ? (
            <div className="flex items-center justify-center py-12">
              <div className="animate-spin rounded-full h-10 w-10 border-t-2 border-b-2 border-green-600"></div>
            </div>
          ) : filteredSharedItems.length > 0 ? (
            <div className="overflow-x-auto">
              <table className="min-w-full bg-white border border-gray-200 rounded-lg">
                <thead>
                  <tr className="bg-green-100 text-left">
                    <th className="py-3 px-4 border-b font-semibold text-green-700">Title</th>
                    <th className="py-3 px-4 border-b font-semibold text-green-700">Owner</th>
                    <th className="py-3 px-4 border-b font-semibold text-green-700">Price</th>
                    <th className="py-3 px-4 border-b font-semibold text-green-700">Expiration</th>
                    <th className="py-3 px-4 border-b font-semibold text-green-700">Status</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredSharedItems.map((item) => (
                    <tr
                      key={item.id}
                      className="hover:bg-green-50 transition-colors cursor-pointer"
                      onClick={() => setSelectedItem(item)} // Set selected item on click
                    >
                      <td className="py-3 px-4 border-b text-gray-700">{item.title || 'N/A'}</td>
                      <td className="py-3 px-4 border-b text-gray-700">{item.owner || 'N/A'}</td>
                      <td className="py-3 px-4 border-b text-gray-600">{item.price || 'N/A'}</td>
                      <td className="py-3 px-4 border-b text-gray-600">{item.expiration || 'N/A'}</td>
                      <td className="py-3 px-4 border-b text-gray-600">{item.status || 'N/A'}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          ) : (
            <div className="text-center py-12">
              <p className="text-gray-600">No shared items found matching your criteria.</p>
            </div>
          )}

          {/* Modal for Item Details */}
          {selectedItem && (
            <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
              {/* Backdrop */}
              <div
                className="fixed inset-0 bg-black bg-opacity-50 backdrop-blur-sm transition-opacity duration-300"
                onClick={() => setSelectedItem(null)} // Close modal on backdrop click
              />
              {/* Modal Content */}
              <div className="relative bg-white rounded-2xl shadow-2xl w-full max-w-md p-6">
                <button
                  className="absolute top-4 right-4 text-gray-400 hover:text-gray-600"
                  onClick={() => setSelectedItem(null)} // Close modal on button click
                >
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    className="h-6 w-6"
                    fill="none"
                    viewBox="0 0 24 24"
                    stroke="currentColor"
                  >
                    <path
                      strokeLinecap="round"
                      strokeLinejoin="round"
                      strokeWidth={2}
                      d="M6 18L18 6M6 6l12 12"
                    />
                  </svg>
                </button>
                <h3 className="text-xl font-bold text-gray-800 mb-4">{selectedItem.title}</h3>
                <img
                  src={selectedItem.imageUrl || 'https://via.placeholder.com/150'}
                  alt={selectedItem.title}
                  className="w-full h-64 object-cover rounded-lg mb-4"
                />
                <p className="text-gray-600 mb-4">{selectedItem.description || 'No description available.'}</p>
                <p className="text-gray-600 mb-2">
                  <strong>Owner:</strong> {selectedItem.owner || 'N/A'}
                </p>
                <p className="text-gray-600 mb-2">
                  <strong>Price:</strong> {selectedItem.price || 'N/A'}
                </p>
                <p className="text-gray-600 mb-2">
                  <strong>Expiration:</strong> {selectedItem.expiration || 'N/A'}
                </p>
                <p className="text-gray-600">
                  <strong>Status:</strong> {selectedItem.status || 'N/A'}
                </p>
                {selectedItem.status !== 'Available' && (
                  <button
                    onClick={() => removeItem(selectedItem.id)} // Remove item on click
                    className="mt-4 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700"
                  >
                    Remove Item
                  </button>
                )}
              </div>
            </div>
          )}
        </div>
      );
    } else if (selectedView === 'recyclingInfo') {
      return renderRecyclingInfo();
    } else if (selectedView === 'schedules') {
      return renderSchedules();
    } else if (selectedView === 'immediatePickups') {
      return renderImmediatePickups();
    } else if (selectedView === 'binStatus') {
      return renderBinStatus();
    } else if (selectedView === 'binRequests') {
      return renderBinRequests();
    } else if (selectedView === 'reportedIssues') {
      return renderReportedIssues(); // Render the detailed table for reported issues
    }

    return (
      <div className="flex flex-col items-center justify-center mt-20 p-8">
        <div className="text-6xl text-green-200 mb-4">
          <FaLeaf />
        </div>
        <p className="text-gray-500 text-center max-w-md">
          Select an option from the navigation menu to get started.
        </p>
      </div>
    );
  };

  useEffect(() => {
    const fetchDashboardMetrics = async () => {
      try {
        // Fetch total users
        const usersSnapshot = await getDocs(collection(db, 'users'));
        setTotalUsers(usersSnapshot.size);
  
        // Fetch active bins
        const binsSnapshot = await getDocs(collection(db, 'bins'));
        const activeBinsCount = binsSnapshot.docs.filter((doc) => doc.data().status === 'Active').length;
        setActiveBins(activeBinsCount);
  
        // Fetch immediate pickup requests
        const pickupsSnapshot = await getDocs(collection(db, 'immediate_pickups'));
        setImmediatePickupRequests(pickupsSnapshot.size);
      } catch (err) {
        console.error('Error fetching dashboard metrics:', err);
      }
    };
  
    if (selectedView === 'overview') {
      fetchDashboardMetrics();
    }
  }, [selectedView]);

  const fetchHomeNumbers = async () => {
    try {
      const usersSnapshot = await getDocs(collection(db, 'users'));
      const uniqueHomeNumbers = [
        ...new Set(usersSnapshot.docs.map((doc) => doc.data().homeNumber).filter(Boolean)),
      ];
      setHomeNumbers(uniqueHomeNumbers);
    } catch (err) {
      console.error('Error fetching home numbers:', err);
    }
  };

  const fetchBinsForHomeNumber = async (homeNumber) => {
    try {
      const binsSnapshot = await getDocs(collection(db, 'bins'));
      const relatedBins = binsSnapshot.docs
        .map((doc) => ({ id: doc.id, ...doc.data() }))
        .filter((bin) => bin.homeNumber === homeNumber);
      setBins(relatedBins);
    } catch (err) {
      console.error('Error fetching bins:', err);
    }
  };

  const fetchBinRequests = async () => {
    try {
      const requestsSnapshot = await getDocs(collection(db, 'binRequests'));
      setBinRequests(
        requestsSnapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() }))
      );
    } catch (err) {
      console.error('Error fetching bin requests:', err);
    }
  };

  const handleActivateBin = async (binId) => {
    try {
      await updateDoc(doc(db, 'bins', binId), { status: 'Active' });
      setBins((prev) =>
        prev.map((bin) => (bin.id === binId ? { ...bin, status: 'Active' } : bin))
      );
    } catch (err) {
      console.error('Error activating bin:', err);
    }
  };

  const handleApproveBinRequest = async (requestId, homeNumber) => {
    try {
      const newBin = { homeNumber, status: 'Inactive' };
      const binDoc = await addDoc(collection(db, 'bins'), newBin);
      setBins((prev) => [...prev, { id: binDoc.id, ...newBin }]);

      await deleteDoc(doc(db, 'binRequests', requestId));
      setBinRequests((prev) => prev.filter((request) => request.id !== requestId));
    } catch (err) {
      console.error('Error approving bin request:', err);
    }
  };

  const renderNavigation = () => (
    <nav className="p-4 flex-grow bg-gradient-to-b from-green-50 to-white">
      <ul className="space-y-2">
        {navCategories.map((category, idx) => (
          <li key={idx} className="mb-1">
            {/* Main category button */}
            <button
              onClick={() => toggleCategory(idx)}
              className={`flex items-center justify-between w-full px-5 py-4 text-sm rounded-xl transition-all duration-200 ${
                expandedCategory === idx
                  ? 'bg-gradient-to-r from-green-600 to-green-500 text-white shadow-md'
                  : 'hover:bg-green-100 text-gray-700'
              }`}
            >
              <div className="flex items-center">
                <div
                  className={`flex items-center justify-center w-10 h-10 rounded-lg ${
                    expandedCategory === idx ? 'bg-white/20' : 'bg-green-100'
                  }`}
                >
                  <span
                    className={`text-xl ${
                      expandedCategory === idx ? 'text-white' : 'text-green-600'
                    }`}
                  >
                    {category.icon}
                  </span>
                </div>
                <span className="ml-4 font-semibold">{category.title}</span>
              </div>
              {category.items.length > 1 && (
                <span className="text-sm">
                  {expandedCategory === idx ? <FaChevronDown /> : <FaChevronRight />}
                </span>
              )}
            </button>

            {/* Submenu */}
            {expandedCategory === idx && (
              <ul className="mt-2 ml-6 pl-6 border-l-2 border-green-200 space-y-2">
                {category.items.map((item, itemIdx) => (
                  <li key={itemIdx}>
                    <button
                      onClick={item.action || (() => item.view && setSelectedView(item.view))}
                      className="flex items-center px-4 py-3 text-sm rounded-xl hover:bg-green-50 text-gray-600 transition-colors w-full text-left"
                    >
                      <div className="w-8 h-8 flex items-center justify-center rounded-lg bg-green-100 mr-3">
                        <span className="text-green-600">{item.icon}</span>
                      </div>
                      <span className="font-medium">{item.label}</span>
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </li>
        ))}
      </ul>
    </nav>
  );

  const handleEditUser = () => {
    setEditUserData(userData); // Pre-fill user data for editing
    setIsEditing(true); // Enable edit mode
  };

  const handleSaveUser = async () => {
    if (!editUserData) return;

    try {
      await updateDoc(doc(db, 'users', auth.currentUser.uid), editUserData); // Update user data in Firestore
      setUserData(editUserData); // Update local state
      setIsEditing(false); // Exit edit mode
    } catch (err) {
      console.error('Error saving user data:', err);
    }
  };

  const renderUserDetails = () => (
    <div className="p-6 space-y-5">
      {isEditing ? (
        <div className="space-y-4">
          <input
            type="text"
            value={editUserData.name || ''}
            onChange={(e) => setEditUserData({ ...editUserData, name: e.target.value })}
            placeholder="Name"
            className="w-full p-2 border border-gray-300 rounded-lg"
          />
          <input
            type="text"
            value={editUserData.phone || ''}
            onChange={(e) => setEditUserData({ ...editUserData, phone: e.target.value })}
            placeholder="Phone"
            className="w-full p-2 border border-gray-300 rounded-lg"
          />
          <div className="flex justify-end space-x-3">
            <button
              onClick={() => setIsEditing(false)} // Cancel edit mode
              className="px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 rounded-lg"
            >
              Cancel
            </button>
            <button
              onClick={handleSaveUser} // Save changes
              className="px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
            >
              Save
            </button>
          </div>
        </div>
      ) : (
        <div>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <p className="text-xs font-medium text-gray-500 uppercase">Name</p>
              <p className="text-base font-medium text-gray-800">{userData.name}</p>
            </div>
            <div>
              <p className="text-xs font-medium text-gray-500 uppercase">Phone</p>
              <p className="text-base font-medium text-gray-800">{userData.phone || 'Not provided'}</p>
            </div>
          </div>
          <button
            onClick={handleEditUser} // Enable edit mode
            className="mt-4 px-4 py-2 bg-green-600 text-white rounded-lg hover:bg-green-700"
          >
            Edit
          </button>
        </div>
      )}
    </div>
  );

  return (
    <div className="flex h-screen bg-green-50">
      {/* Mobile menu button */}
      <button
        className="lg:hidden fixed z-20 top-4 left-4 p-3 rounded-full bg-green-600 text-white shadow-lg"
        onClick={toggleSidebar}
      >
        {sidebarOpen ? <FaTimes /> : <FaBars />}
      </button>

      {/* Sidebar/Navigation */}
      <aside
        className={`${
          sidebarOpen ? 'translate-x-0' : '-translate-x-full'
        } fixed lg:relative inset-y-0 left-0 z-10 w-80 transition-transform duration-300 ease-in-out bg-white/90 backdrop-blur-lg shadow-2xl lg:translate-x-0 overflow-y-auto flex flex-col`}
      >
        {/* Logo area */}
        <div className="relative h-24 px-8 flex items-center justify-between bg-gradient-to-r from-green-600 to-green-500 text-white overflow-hidden">
          <div className="flex items-center">
            <div className="p-3 bg-white rounded-full shadow-md">
              <FaLeaf className="text-2xl text-green-600" />
            </div>
            <span className="ml-3 text-2xl font-bold tracking-wide">Clearo Sync</span>
          </div>
          
          {/* Decorative elements */}
          <div className="absolute -bottom-8 -left-8 w-16 h-16 bg-white/10 rounded-full"></div>
          <div className="absolute -top-4 -right-4 w-16 h-16 bg-white/10 rounded-full"></div>
        </div>

        {/* User info */}
        {userData && (
          <div className="px-8 py-6 border-b border-green-100 bg-gradient-to-r from-green-50 to-green-100">
            <div className="flex items-center">
              <div className="relative">
                <div className="w-14 h-14 rounded-full bg-gradient-to-br from-green-500 to-green-600 flex items-center justify-center text-white font-medium text-xl shadow-md">
                  {userData.name.charAt(0).toUpperCase()}
                </div>
                <div className="absolute -bottom-1 -right-1 w-6 h-6 bg-white rounded-full flex items-center justify-center border-2 border-green-500">
                  <FaLeaf className="text-green-500 text-xs" />
                </div>
              </div>
              <div className="ml-4">
                <p
                  className="font-bold text-gray-800 text-lg cursor-pointer hover:underline"
                  onClick={openModal} // Open modal on click
                >
                  {userData.name}
                </p>
                <p className="text-sm text-green-700">{userData.position}</p>
              </div>
            </div>
          </div>
        )}

        {/* Navigation - Collapsible */}
        {renderNavigation()}

        {/* Nature elements decoration */}
        <div className="px-6 py-4 bg-green-100/50 flex items-center justify-around text-green-500 border-t border-green-100">
          <FaLeaf className="text-xl" />
          <FaSeedling className="text-xl" />
          <FaTree className="text-xl" />
          <FaWater className="text-xl" />
          <FaSun className="text-xl" />
        </div>

        {/* Logout */}
        <div className="p-6 border-t border-green-100">
          <button
            onClick={logout}
            className="flex items-center justify-center w-full px-5 py-4 text-sm bg-red-50 text-red-500 hover:bg-red-100 rounded-xl transition-colors font-medium"
          >
            <FaSignOutAlt className="mr-2" />
            <span>Logout</span>
          </button>
        </div>
      </aside>

      {/* Main content */}
      <main className="flex-1 overflow-y-auto">
        {isLoading ? (
          <div className="flex items-center justify-center h-full">
            <div className="animate-spin rounded-full h-14 w-14 border-4 border-green-200 border-t-green-600"></div>
          </div>
        ) : (
          <div className="p-6 max-w-5xl mx-auto">
            <div className="bg-white/80 backdrop-blur-md rounded-3xl shadow-lg p-8 border border-green-100">
              <div className="flex items-center justify-between">
                <div>
                  <h2 className="text-2xl font-bold text-gray-800 mb-2">
                    Welcome, <span className="text-green-600">{userData?.name}</span>!
                  </h2>
                  <p className="text-green-600 font-medium">{userData?.position}</p>
                  <p className="text-gray-600 mt-3 max-w-2xl">
                    You are now logged into the Clearo Sync Admin Dashboard. Explore the navigation on the left to manage your tasks.
                  </p>
                </div>
                <div className="hidden md:block">
                  <div className="p-4 bg-green-100 rounded-2xl text-green-600 text-4xl">
                    <FaLeaf />
                  </div>
                </div>
              </div>
            </div>
            
            {/* Dynamic content based on selected view */}
            {renderContent()}
          </div>
        )}
      </main>

     
    {/* Modal */}
{showModal && (
  <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
    {/* Backdrop */}
    <div 
      className="fixed inset-0 bg-black bg-opacity-50 backdrop-blur-sm transition-opacity duration-300"
      onClick={closeModal}
    />
    
    {/* Modal Container */}
    <div className="relative bg-white rounded-2xl shadow-2xl w-full max-w-md transform transition-all duration-300 animate-fade-in-up overflow-hidden">
      {/* Header with User Identity */}
      <div className="bg-gradient-to-r from-green-50 to-green-100 p-6 flex items-start justify-between">
        <div className="flex items-center space-x-4">
          <div className="relative flex-shrink-0">
            <div className="w-14 h-14 rounded-full bg-gradient-to-br from-green-500 to-green-600 flex items-center justify-center text-white text-xl font-bold shadow-lg">
              {userData.name.charAt(0).toUpperCase()}
            </div>
            <div className="absolute -bottom-1 -right-1 w-6 h-6 bg-white rounded-full flex items-center justify-center border-2 border-green-500">
              <FaUserCircle className="text-green-500 text-xs" />
            </div>
          </div>
          <div className="min-w-0">
            <h2 className="text-xl font-bold text-gray-800 truncate">{userData.name}</h2>
            <p className="text-sm text-gray-600 truncate flex items-center">
              <FaEnvelope className="mr-1.5 text-green-500 text-opacity-80" size={12} />
              {userData.email}
            </p>
          </div>
        </div>
        <button
          className="text-gray-400 hover:text-gray-600 transition-colors duration-200 p-1 rounded-full hover:bg-gray-200/50"
          onClick={closeModal}
        >
          <svg
            xmlns="http://www.w3.org/2000/svg"
            className="h-5 w-5"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M6 18L18 6M6 6l12 12"
            />
          </svg>
        </button>
      </div>

      {/* Details Section */}
      {renderUserDetails()}

      {/* Footer Actions */}
      <div className="px-6 py-4 bg-gray-50 flex justify-end space-x-3 border-t border-gray-100">
        <button
          onClick={closeModal}
          className="px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 rounded-lg transition-colors duration-200"
        >
          Close
        </button>
        <button
          className="px-4 py-2 bg-green-600 hover:bg-green-700 text-white text-sm font-medium rounded-lg transition-colors duration-200 shadow-sm flex items-center"
          onClick={() => {/* Edit handler */}}
        >
          <FaEdit className="mr-2" size={14} />
          Edit Profile
        </button>
      </div>
    </div>
  </div>
)}
    {renderPopup()}
    {/* Confirmation Popup */}
    {showConfirmPopup && (
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
        {/* Backdrop */}
        <div
          className="fixed inset-0 bg-black bg-opacity-50 backdrop-blur-sm transition-opacity duration-300"
          onClick={() => setShowConfirmPopup(false)} // Close popup on backdrop click
        />
        {/* Popup Content */}
        <div className="relative bg-white rounded-2xl shadow-2xl w-full max-w-md p-6">
          <h3 className="text-xl font-bold text-gray-800 mb-4">Confirm Pickup</h3>
          <p className="text-gray-600 mb-4">
            Are you sure you want to confirm the pickup for <strong>{pickupToConfirm?.bin}</strong>?
          </p>
          <div className="flex justify-end space-x-3">
            <button
              onClick={() => setShowConfirmPopup(false)} // Close popup
              className="px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 rounded-lg transition-colors duration-200"
            >
              Cancel
            </button>
            <button
              onClick={handleConfirmPickupPopup} // Confirm the pickup
              className="px-4 py-2 bg-green-600 hover:bg-green-700 text-white text-sm font-medium rounded-lg transition-colors duration-200"
            >
              Confirm
            </button>
          </div>
        </div>
      </div>
    )}
    {/* Edit Status Popup */}
    {showEditStatusPopup && (
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
        {/* Backdrop */}
        <div
          className="fixed inset-0 bg-black bg-opacity-50 backdrop-blur-sm transition-opacity duration-300"
          onClick={() => setShowEditStatusPopup(false)} // Close popup on backdrop click
        />
        {/* Popup Content */}
        <div className="relative bg-white rounded-2xl shadow-2xl w-full max-w-md p-6">
          <h3 className="text-xl font-bold text-gray-800 mb-4">Edit Status</h3>
          <p className="text-gray-600 mb-4">
            Change the status for <strong>{pickupToEditStatus?.bin}</strong>.
          </p>
          <div className="flex justify-end space-x-3">
            <button
              onClick={() => handleEditStatus('Pending')} // Set status to Pending
              className="px-4 py-2 bg-yellow-500 hover:bg-yellow-600 text-white text-sm font-medium rounded-lg transition-colors duration-200"
            >
              Pending
            </button>
            <button
              onClick={() => handleEditStatus('Confirmed')} // Set status to Confirmed
              className="px-4 py-2 bg-green-600 hover:bg-green-700 text-white text-sm font-medium rounded-lg transition-colors duration-200"
            >
              Confirmed
            </button>
          </div>
        </div>
      </div>
    )}
    {/* Dialog for editing status */}
    {showEditStatusPopup && (
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
        {/* Backdrop */}
        <div
          className="fixed inset-0 bg-black bg-opacity-50 backdrop-blur-sm transition-opacity duration-300"
          onClick={() => setShowEditStatusPopup(false)} // Close dialog on backdrop click
        />
        {/* Dialog Content */}
        <div className="relative bg-white rounded-2xl shadow-2xl w-full max-w-md p-6">
          <h3 className="text-xl font-bold text-gray-800 mb-4">Confirm Bin Request</h3>
          <p className="text-gray-600 mb-4">
            Are you sure you want to confirm the bin request for <strong>{pickupToEditStatus?.id}</strong>?
          </p>
          <div className="flex justify-end space-x-3">
            <button
              onClick={() => setShowEditStatusPopup(false)} // Close dialog
              className="px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 rounded-lg transition-colors duration-200"
            >
              Cancel
            </button>
            <button
              onClick={handleEditPickupStatus} // Confirm the status
              className="px-4 py-2 bg-green-600 hover:bg-green-700 text-white text-sm font-medium rounded-lg transition-colors duration-200"
            >
              Confirm
            </button>
          </div>
        </div>
      </div>
    )}
    {/* Dialog for replying to an issue */}
    {showIssueDialog && (
      <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
        {/* Backdrop */}
        <div
          className="fixed inset-0 bg-black bg-opacity-50 backdrop-blur-sm transition-opacity duration-300"
          onClick={() => setShowIssueDialog(false)} // Close dialog on backdrop click
        />
        {/* Dialog Content */}
        <div className="relative bg-white rounded-2xl shadow-2xl w-full max-w-md p-6">
          <h3 className="text-xl font-bold text-gray-800 mb-4">Reply to Issue</h3>
          <p className="text-gray-600 mb-4">
            Issue ID: <strong>{selectedIssue?.id}</strong>
          </p>
          <textarea
            value={issueReply}
            onChange={(e) => setIssueReply(e.target.value)}
            placeholder="Enter your reply"
            className="w-full p-3 border border-gray-300 rounded-lg mb-4"
          />
          <textarea
            value={issueAction}
            onChange={(e) => setIssueAction(e.target.value)}
            placeholder="Enter the action to be taken"
            className="w-full p-3 border border-gray-300 rounded-lg mb-4"
          />
          <div className="flex justify-end space-x-3">
            <button
              onClick={() => setShowIssueDialog(false)} // Close dialog
              className="px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-100 rounded-lg transition-colors duration-200"
            >
              Cancel
            </button>
            <button
              onClick={handleSaveIssueResponse} // Save reply and action
              className="px-4 py-2 bg-green-600 hover:bg-green-700 text-white text-sm font-medium rounded-lg transition-colors duration-200"
            >
              Save
            </button>
          </div>
        </div>
      </div>
    )}
    </div>
  );
}