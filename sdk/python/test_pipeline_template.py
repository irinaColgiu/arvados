# usage example:
#
# ARVADOS_API_TOKEN=abc ARVADOS_API_HOST=arvados.local python -m unittest discover

import unittest
import arvados
import apiclient

class PipelineTemplateTest(unittest.TestCase):
    def runTest(self):
        pt_uuid = arvados.service.pipeline_templates().create(
            body={'name':__file__}
            ).execute()['uuid']
        self.assertEqual(len(pt_uuid), 27,
                         'Unexpected format of pipeline template UUID ("%s")'
                         % pt_uuid)
        components = {
            'x': 'x',
            '-x-': [1,2,{'foo':'bar'}],
            'Boggis': {'Bunce': '[\'Bean\']'},
            'SpassBox': True,
            'spass_box': False,
            'spass-box': [True, 'Maybe', False]
            }
        update_response = arvados.service.pipeline_templates().update(
            uuid=pt_uuid,
            body={'components':components}
            ).execute()
        self.assertEqual('uuid' in update_response, True,
                         'update() response did not include a uuid')
        self.assertEqual(update_response['uuid'], pt_uuid,
                         'update() response has a different uuid (%s, not %s)'
                         % (update_response['uuid'], pt_uuid))
        self.assertEqual(update_response['name'], __file__,
                         'update() response has a different name (%s, not %s)'
                         % (update_response['name'], __file__))
        get_response = arvados.service.pipeline_templates().get(
            uuid=pt_uuid
            ).execute()
        self.assertEqual(get_response['components'], components,
                         'components got munged by server (%s -> %s)'
                         % (components, update_response['components']))
        delete_response = arvados.service.pipeline_templates().delete(
            uuid=pt_uuid
            ).execute()
        self.assertEqual(delete_response['uuid'], pt_uuid,
                         'delete() response has wrong uuid (%s, not %s)'
                         % (delete_response['uuid'], pt_uuid))
        with self.assertRaises(apiclient.errors.HttpError):
            geterror_response = arvados.service.pipeline_templates().get(
                uuid=pt_uuid
                ).execute()
