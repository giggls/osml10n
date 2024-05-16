#!/usr/bin/env python3

import argparse
import asyncio
import icu
import unicodedata
import json
import os
import pathlib
import shapely.geometry
import shapely.prepared
import struct
import sys
import pkg_resources
from importlib.metadata import version

# as imports are very slow parse arguments first
parser = argparse.ArgumentParser(
    description="Server for transcription of names based on geolocation"
)
parser.add_argument(
    "-b", "--bindaddr", type=str, default="localhost", help="local bind address"
)
parser.add_argument("-p", "--port", default=8033, help="port to listen at")
parser.add_argument(
    "-s",
    "--sdnotify",
    action="store_true",
    help="Signal systemd when daemon is ready to serve",
)
parser.add_argument("-v", "--verbose", action="store_true", help="print verbose output")
parser.add_argument("-g", "--geomdir", help="Directory with geometries")

args = parser.parse_args()


def vout(msg):
    if args.verbose:
        sys.stdout.write(msg)
        sys.stdout.flush()


try:
    vers = "version " + pkg_resources.require("osml10n")[0].version
except:
    vers = "uninstalled version"
    if args.geomdir is None:
        args.geomdir = os.path.join("osml10n", "boundaries")

sys.stdout.write("Loading osml10n transcription server (%s): " % vers)
sys.stdout.flush()
vout("\n")


try:
    # Kanji in JP
    import pykakasi
except Exception as ex:
    sys.stderr.write(
        "\nERROR: unable to load python module pykakasi! Probably the following command will work:\n"
    )
    sys.stderr.write("pip install pykakasi\n\n")
    sys.stderr.write("Error message was:\n%s\n" % ex)
    sys.exit(1)

try:
    # thai language in TH
    import tltk
except Exception as ex:
    sys.stderr.write(
        "\nERROR: unable to load python module tltk! Probably the following command will work:\n"
    )
    sys.stderr.write("pip install tltk\n\n")
    sys.stderr.write("Error message was:\n%s\n" % ex)
    sys.exit(1)

try:
    # Cantonese transcription
    import pinyin_jyutping_sentence
except Exception as ex:
    sys.stderr.write(
        "\nERROR: unable to load python module pinyin_jyutping_sentence! Probably the following command will work:\n"
    )
    sys.stderr.write("pip install pinyin_jyutping_sentence\n\n")
    sys.stderr.write("Error message was:\n%s\n" % ex)
    sys.exit(1)


def split_by_alphabet(str):
    strlist = []
    target = ""
    oldalphabet = unicodedata.name(str[0]).split(" ")[0]
    target = str[0]
    for c in str[1:]:
        alphabet = unicodedata.name(c).split(" ")[0]
        if alphabet == oldalphabet:
            target = target + c
        else:
            strlist.append(target)
            target = c
        oldalphabet = alphabet
    strlist.append(target)
    return strlist


def thai_transcript(inpstr):
    stlist = split_by_alphabet(inpstr)

    latin = ""
    for st in stlist:
        if unicodedata.name(st[0]).split(" ")[0] == "THAI":
            transcript = ""
            try:
                transcript = tltk.nlp.th2roman(st).rstrip("<s/>").rstrip()
            except Exception:
                sys.stderr.write("tltk error transcribing >%s<\n" % st)
                return None
            latin = latin + transcript
        else:
            latin = latin + st
    return latin


def cantonese_transcript(inpstr):
    stlist = split_by_alphabet(inpstr)

    latin = ""
    for st in stlist:
        if unicodedata.name(st[0]).split(" ")[0] == "CJK":
            transcript = ""
            try:
                transcript = pinyin_jyutping_sentence.jyutping(st, spaces=True)
            except Exception:
                sys.stderr.write(
                    "pinyin_jyutping_sentence error transcribing >%s<\n" % st
                )
                return None
            latin = latin + transcript
        else:
            latin = latin + st
    return latin


# helper function "contains_thai"
# checks if string contains Thai language characters
# 0x0400-0x04FF in unicode table
def contains_thai(text):
    for c in text:
        if (ord(c) > 0x0E00) and (ord(c) < 0x0E7F):
            return True
    return False


# helper function "contains_cjk"
# checks if string contains CJK characters
# 0x4e00-0x9FFF in unicode table
def contains_cjk(text):
    for c in text:
        if (ord(c) > 0x4E00) and (ord(c) < 0x9FFF):
            return True
    return False


class transcriptor:
    def __init__(self):
        # ICU transliteration instance
        self.icutr = icu.Transliterator.createInstance("Any-Latin").transliterate

        # Kanji to Latin transcription instance via pykakasi
        self.kakasi = pykakasi.kakasi()

    def transcript(self, id, country, unistr):
        if country == "":
            vout("doing transcription for >>%s<< (generic, osm_id %s)\n" % (unistr, id))
        else:
            vout(
                "doing transcription for >>%s<< (country %s, osm_id %s)\n"
                % (unistr, country, id)
            )
        if country == "jp":
            # this should mimic the old api behavior (I hate API changes)
            # new API does not have all options anymore :(
            kanji = self.kakasi.convert(unistr)
            out = ""
            for w in kanji:
                w["hepburn"] = w["hepburn"].strip()
                if len(w["hepburn"]) > 0:
                    out = out + w["hepburn"].capitalize() + " "
            return out.strip()

        if country == "th":
            return thai_transcript(unistr)

        if country in ["mo", "hk"]:
            return cantonese_transcript(unistr)

        return unicodedata.normalize("NFC", self.icutr(unistr))


class Coord2Country:
    features = []

    # Read all GeoJSON files in the specified directory and return as an array
    # of GeoJSON features.
    @staticmethod
    def read_boundaries(dirname):
        features = []
        if dirname is None:
            for path in pkg_resources.resource_listdir("osml10n", "boundaries"):
                if path.endswith(".geojson"):
                    f = pkg_resources.resource_string(
                        "osml10n", "boundaries/" + path
                    ).decode("utf-8")
                    features.extend(json.loads(f)["features"])
        else:
            for path in pathlib.Path(dirname).iterdir():
                if path.is_file() and path.suffix == ".geojson":
                    with open(path) as f:
                        features.extend(json.load(f)["features"])
        return features

    def __init__(self, dirname):
        features = self.read_boundaries(dirname)
        boundaries = []
        for feature in features:
            geom = shapely.geometry.shape(feature["geometry"])
            cc = feature["properties"]["cc"]
            boundaries.append(cc)
            self.features.append([shapely.prepared.prep(geom), cc])
        vout(f"Found boundaries: {boundaries}")

    def getCountry(self, id, lon, lat):
        if lon == "" or lat == "":
            return ""
        p = shapely.geometry.Point(float(lon), float(lat))
        for f in self.features:
            if f[0].contains(p):
                country = f[1]
                vout("country for %s/%s is %s (osm_id %s)\n" % (lon, lat, country, id))
                return f[1]
        vout("country for %s/%s is unknown (osm_id %s)\n" % (lon, lat, id))
        return ""


co2c = Coord2Country(args.geomdir)
tc = transcriptor()


# Read a request from the socket. First read 4 bytes containing the length
# of the request data, then read the data itself and return as a UTF-8 string.
# Return 'None' if the connection was closed.
async def read_request(reader):
    try:
        lendata = await reader.readexactly(4)
        if len(lendata) == 0:
            return
        length = struct.unpack("I", lendata)
        if length == 0:
            return
        data = await reader.readexactly(length[0])
        return data.decode("utf-8")
    except asyncio.exceptions.IncompleteReadError:
        return


# Write the reply data to the socket and flush. First writes 4 bytes containing
# the length of the data and then the data itself.
async def send_reply(writer, reply):
    data = reply.encode("utf-8")
    length = len(data)
    writer.write(struct.pack("I", length) + data)
    await writer.drain()


async def handle_connection(reader, writer):
    vout("New connection\n")
    while True:
        id = "unknown"
        try:
            data = await read_request(reader)
            if data is None:
                vout("Connection closed\n")
                return

            # We support the following formats:
            # CC/id/cc/string
            # XY/id/lon/lat/string
            cmd = data[0:2]
            if cmd == "CC":
                (id, cc, name) = data[3:].split("/", 2)
            elif cmd == "XY":
                (id, lon, lat, name) = data[3:].split("/", 3)
                # Do check for country only if string contains Thai or CJK characters
                if contains_cjk(name):
                    cc = co2c.getCountry(id, lon, lat)
                else:
                    if contains_thai(name):
                        cc = "th"
                    else:
                        cc = ""
            else:
                sys.stderr.write(f"Ignore unkown command '{cmd}'\n")
                await send_reply(writer, "")
                continue

            if name != "":
                reply = tc.transcript(id, cc, name)
            else:
                reply = ""

            if isinstance(reply, str):
                await send_reply(writer, reply)
            else:
                sys.stderr.write(
                    f"Error in id '{id}': transcript('{cc}','{name}') returned non-string '{reply}'\n"
                )
                await send_reply(writer, "")
        except BaseException as err:
            sys.stderr.write(f"Error in id '{id}': {err}, {type(err)}\n")
            await send_reply(writer, "")


async def main():
    server = await asyncio.start_server(
        handle_connection,
        host=args.bindaddr,
        port=args.port,
        reuse_address=True,
        reuse_port=True,
    )
    addrs = ", ".join(str(sock.getsockname()) for sock in server.sockets)
    vout(f"Serving on {addrs}\n")

    async with server:
        await server.serve_forever()


if __name__ == "__main__":
    sys.stdout.write(
        "ready.\n(using pykakasi "
        + version("pykakasi")
        + ", "
        + "tltk "
        + version("tltk")
        + ", "
        + "pinyin_jyutping_sentence "
        + version("pinyin_jyutping_sentence")
        + ")\n"
    )
    if args.sdnotify:
        import sdnotify

        sdnotify.SystemdNotifier().notify("READY=1")
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("Stopping server\n")
