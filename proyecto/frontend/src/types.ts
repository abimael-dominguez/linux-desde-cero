export type EventItem = {
  id: string;
  title: string;
  event_type: string;
  description: string;
  starts_at: string;
  location: string;
  image_path: string | null;
  created_at: string;
  updated_at: string;
};

export type EventFormValues = {
  title: string;
  eventType: string;
  description: string;
  startsAt: string;
  location: string;
};
