from django.core.management.base import BaseCommand
from reminder.tasks import send_drink_reminder_task

class Command(BaseCommand):
    help = 'Send a drink reminder notification manually'

    def handle(self, *args, **options):
        self.stdout.write('Sending drink reminder...')
        result = send_drink_reminder_task.delay()
        self.stdout.write(
            self.style.SUCCESS(f'Drink reminder task queued with ID: {result.id}')
        )