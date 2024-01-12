from dataclasses import dataclass
from typing import TextIO

from shake_data import SHAKE_LIST


@dataclass
class Track:
    name: str
    length: int
    values: list[list[float]]


@dataclass
class Animation:
    name: str
    tracks: list[Track]


def write_keys(file: TextIO, track: Track) -> None:
    file.write('"times": PackedFloat32Array(')
    for i in range(track.length):
        file.write(f"{i}")
        if i != track.length - 1:
            file.write(f", ")
    file.write('),\n')

    file.write('"transitions": PackedFloat32Array(')
    for i in range(track.length):
        file.write(f"1")
        if i != track.length - 1:
            file.write(f", ")
    file.write('),\n')

    file.write('"update": 0,\n')

    file.write('"values": [')

    for i, vector in enumerate(track.values):
        file.write("Vector3(")
        for j, num in enumerate(vector):
            file.write(f"{num}")
            if j != len(vector) - 1:
                file.write(f", ")
        file.write(")")
        if i != len(track.values) - 1:
            file.write(f", ")

    file.write(']\n')

    file.write('}\n')


def write_track_metadata(file: TextIO, track_number: int, track: Track) -> None:
    data = [f"tracks/{track_number}/type = \"value\"", f"tracks/{track_number}/imported = false",
            f"tracks/{track_number}/enabled = true", f"tracks/{track_number}/path = NodePath(\".:{track.name}\")",
            f"tracks/{track_number}/interp = 1", f"tracks/{track_number}/loop_wrap = true",
            f"tracks/{track_number}/keys = {{"]

    for line in data:
        file.write(line + '\n')


def extract_shake_data(data: dict) -> list[Animation]:
    animations: list[Animation] = []

    data_keys = data.keys()

    for data_animation in data_keys:
        animation_name: str = str(data_animation).lower()

        tracks_of_animation: list[Track] = []

        raw_position_tracks: list = extract_position_tracks(data.get(data_animation)[2], slice(0, 3))
        raw_rotation_tracks: list = extract_position_tracks(data.get(data_animation)[2], slice(3, None))

        track_length: int = len(raw_position_tracks[0])

        tracks_of_animation.append(extract_values_from_raw_track("position_offsets", track_length, raw_position_tracks))
        tracks_of_animation.append(extract_values_from_raw_track("rotation_offsets", track_length, raw_rotation_tracks))

        animations.append(Animation(animation_name, tracks_of_animation))

    return animations


def extract_position_tracks(data, s: slice) -> list:
    raw_tracks: list = []
    a = list(data)
    b = a[s]
    for key in b:
        raw_tracks.append(data.get(key))

    return raw_tracks


def extract_values_from_raw_track(track_name: str, track_length: int, track: list) -> Track:
    values_of_track: list[list[float]] = []

    for value_index in range(track_length):
        vector3: list[float] = [
            track[0][value_index][1],
            track[1][value_index][1],
            track[2][value_index][1]
        ]
        values_of_track.append(vector3)

    return Track(track_name, track_length, values_of_track)


def main():
    animations: list[Animation] = extract_shake_data(SHAKE_LIST)

    for animation in animations:
        with open(f"syn_{animation.name}", "w") as file:
            for i, track in enumerate(animation.tracks):
                write_track_metadata(file, i, track)
                write_keys(file, track)


if __name__ == '__main__':
    main()
