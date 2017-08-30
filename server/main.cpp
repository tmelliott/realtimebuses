#include <iostream>
#include <iomanip>
#include <fstream>
#include <vector>
#include <algorithm>
#include <string>
#include <sqlite3.h>

#include "gtfs-realtime.pb.h"
#include "gtfs-network.pb.h"

int main (int argc, char* argv[]) {
    GOOGLE_PROTOBUF_VERIFY_VERSION;

    transit_realtime::FeedMessage feed_tu;
    transit_realtime::FeedMessage feed_vp;

    {
        std::string feed_file ("../../data/trip_updates.pb");
        std::fstream feed_in (feed_file, std::ios::in | std::ios::binary);
    	if (!feed_in) {
    		std::cerr << "file not found!\n";
    		return false;
    	} else if (!feed_tu.ParseFromIstream (&feed_in)) {
    		std::cerr << "failed to parse GTFS realtime feed!\n";
    		return false;
    	}
    }

    {
        std::string feed_file ("../../data/vehicle_locations.pb");
        std::fstream feed_in (feed_file, std::ios::in | std::ios::binary);
    	if (!feed_in) {
    		std::cerr << "file not found!\n";
    		return false;
    	} else if (!feed_vp.ParseFromIstream (&feed_in)) {
    		std::cerr << "failed to parse GTFS realtime feed!\n";
    		return false;
    	}
    }
    // We're all good!

    transit_network::Feed network;

    // first add all the positions:
    for (auto& vp: feed_vp.entity ()) {
        if (vp.has_vehicle () &&
            vp.vehicle ().has_vehicle () &&
            vp.vehicle ().vehicle ().has_id () &&
            vp.vehicle ().has_position ()) {

            transit_network::Vehicle* v = network.add_vehicles ();
            v->set_id (vp.vehicle ().vehicle ().id ());
            transit_network::Position* p = v->mutable_pos ();
            p->set_lat (vp.vehicle ().position ().latitude ());
            p->set_lng (vp.vehicle ().position ().longitude ());

        }
    }

    // now go through delays and modify or append
    int[5] regions = {0};
    for (auto& tu: feed_tu.entity ()) {
        if (tu.has_trip_update () &&
            tu.trip_update ().has_vehicle () &&
            tu.trip_update ().vehicle ().has_id () &&
            tu.trip_update ().stop_time_update_size () > 0) {

            std::string vid (tu.trip_update ().vehicle ().id ());
            int vi;
            bool matched = false;
            for (int i=0; i<network.vehicles_size (); i++) {
                if (vid == network.vehicles (i).id ()) {
                    matched = true;
                    vi = i;
                    break;
                }
            }

            transit_network::Vehicle* v;
            if (matched) {
                v = network.mutable_vehicles (vi);
            } else {
                v = network.add_vehicles ();
                v->set_id (vid);
            }

            if (tu.trip_update ().stop_time_update (0).has_arrival () &&
                tu.trip_update ().stop_time_update (0).arrival ().has_delay ()) {
                v->set_delay (tu.trip_update ().stop_time_update (0).arrival ().delay ());
                v->set_type (transit_network::Vehicle::ARRIVAL);
            } else if (tu.trip_update ().stop_time_update (0).has_departure () &&
                       tu.trip_update ().stop_time_update (0).departure ().has_delay ()) {
                v->set_delay (tu.trip_update ().stop_time_update (0).departure ().delay ());
                v->set_type (transit_network::Vehicle::DEPARTURE);
            }

            // append to relevant region
        }
    }


    transit_network::Status* nw = network.mutable_status ();
    // std::cout << "Processing " << network.vehicles_size () << " buses:";

    int tbl[8] = {0};
    for (auto& v: network.vehicles ()) {
        if (v.has_delay ()) {
            if (v.delay () < -5*60) {
                tbl[0] += 1;
            } else if (v.delay () < -60) {
                tbl[1] += 1;
            } else if (v.delay () < 5*60) {
                tbl[2] += 1;
            } else if (v.delay () < 10*60) {
                tbl[3] += 1;
            } else if (v.delay () < 20*60) {
                tbl[4] += 1;
            } else if (v.delay () < 30*60) {
                tbl[5] += 1;
            } else {
                tbl[6] += 1;
            }
        } else {
            tbl[7] += 1;
        }
    }

    nw->set_earlier (tbl[0]);
    nw->set_early (tbl[1]);
    nw->set_ontime (tbl[2]);
    nw->set_late (tbl[3]);
    nw->set_later (tbl[4]);
    nw->set_quitelate (tbl[5]);
    nw->set_verylate (tbl[6]);
    nw->set_missing (tbl[7]);

	std::fstream output ("../../data/networkstate.pb",
						 std::ios::out | std::ios::trunc | std::ios::binary);
	if (!network.SerializeToOstream (&output)) {
		std::cerr << "\n x Failed to write ETA feed.\n";
	}
	google::protobuf::ShutdownProtobufLibrary ();

    return 0;
}
